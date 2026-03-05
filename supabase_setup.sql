-- =============================================
-- SUPABASE FULL DATABASE SETUP SCRIPT
-- App: Supa (Car Service Management)
-- Run this in Supabase SQL Editor (Dashboard → SQL)
-- =============================================

-- 1. PROFILES TABLE
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  display_name TEXT,
  phone TEXT,
  avatar_url TEXT,
  role TEXT DEFAULT 'user',            -- 'user' | 'admin'
  fcm_token TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. VEHICLES TABLE
CREATE TABLE IF NOT EXISTS vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  brand TEXT NOT NULL,
  model TEXT NOT NULL,
  year INT,
  license_plate TEXT,
  color TEXT,
  image_url TEXT,
  mileage INT,
  next_service_mileage INT,
  insurance_expiry TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. SERVICES TABLE
CREATE TABLE IF NOT EXISTS services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  price DOUBLE PRECISION NOT NULL DEFAULT 0,
  duration_hours DOUBLE PRECISION DEFAULT 1,
  estimated_time TEXT,
  category TEXT NOT NULL DEFAULT 'catMaintenance',
  image_url TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. ORDERS TABLE
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  car_model TEXT NOT NULL,
  issue_description TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'pending',  -- pending | in_progress | completed | cancelled
  vehicle_id UUID REFERENCES vehicles(id) ON DELETE SET NULL,
  service_id UUID REFERENCES services(id) ON DELETE SET NULL,
  scheduled_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  admin_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. REVIEWS TABLE
CREATE TABLE IF NOT EXISTS reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  rating INT DEFAULT 5,
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. VEHICLE EXPENSES TABLE
CREATE TABLE IF NOT EXISTS vehicle_expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  category TEXT NOT NULL DEFAULT 'other',
  amount DOUBLE PRECISION NOT NULL DEFAULT 0,
  description TEXT,
  date TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. VEHICLE DOCUMENTS TABLE
CREATE TABLE IF NOT EXISTS vehicle_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  file_url TEXT,
  expiry_date TIMESTAMPTZ,
  doc_type TEXT DEFAULT 'other',
  created_at TIMESTAMPTZ DEFAULT NOW()
);


-- =============================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicle_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicle_documents ENABLE ROW LEVEL SECURITY;

-- PROFILES: users see own, admins see all
CREATE POLICY "Users can read own profile"     ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile"   ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admins can read all profiles"   ON profiles FOR SELECT USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "Admins can update all profiles" ON profiles FOR UPDATE USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, display_name)
  VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- VEHICLES: users own their vehicles
CREATE POLICY "Users can CRUD own vehicles" ON vehicles FOR ALL USING (auth.uid() = user_id);

-- SERVICES: everyone can read, admins can manage
CREATE POLICY "Anyone can read services"  ON services FOR SELECT USING (true);
CREATE POLICY "Admins can manage services" ON services FOR ALL USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- ORDERS: users see own, admins see all
CREATE POLICY "Users can read own orders"  ON orders FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own orders" ON orders FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own orders" ON orders FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own orders" ON orders FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "Admins can manage all orders" ON orders FOR ALL USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- REVIEWS
CREATE POLICY "Users can CRUD own reviews" ON reviews FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Anyone can read reviews"    ON reviews FOR SELECT USING (true);

-- EXPENSES
CREATE POLICY "Users can CRUD own expenses" ON vehicle_expenses FOR ALL USING (auth.uid() = user_id);

-- DOCUMENTS
CREATE POLICY "Users can CRUD own documents" ON vehicle_documents FOR ALL USING (auth.uid() = user_id);


-- =============================================
-- STORAGE BUCKETS
-- =============================================

INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('vehicle-images', 'vehicle-images', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('vehicle-documents', 'vehicle-documents', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('service-images', 'service-images', true) ON CONFLICT DO NOTHING;

-- Storage policies: allow authenticated uploads
CREATE POLICY "Authenticated can upload avatars"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'avatars');

CREATE POLICY "Authenticated can upload vehicle images"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'vehicle-images');

CREATE POLICY "Authenticated can upload vehicle docs"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'vehicle-documents');

CREATE POLICY "Authenticated can upload service images"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'service-images');

CREATE POLICY "Public can read all storage"
  ON storage.objects FOR SELECT TO public
  USING (true);


-- =============================================
-- REALTIME (fully via SQL, no Dashboard needed)
-- =============================================

-- Enable realtime for orders (status updates push to client)
ALTER PUBLICATION supabase_realtime ADD TABLE orders;

-- Enable realtime for vehicles (garage changes sync instantly)
ALTER PUBLICATION supabase_realtime ADD TABLE vehicles;

-- Enable realtime for profiles (avatar/name updates sync)
ALTER PUBLICATION supabase_realtime ADD TABLE profiles;

-- NOTE: Realtime respects RLS policies.
-- The SELECT policies above already ensure:
--   • Users only receive updates for their OWN rows
--   • Admins receive updates for ALL rows
-- No additional configuration is required.


-- =============================================
-- INDEXES (performance)
-- =============================================
CREATE INDEX IF NOT EXISTS idx_vehicles_user     ON vehicles(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_user        ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status      ON orders(status);
CREATE INDEX IF NOT EXISTS idx_expenses_vehicle   ON vehicle_expenses(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_documents_vehicle  ON vehicle_documents(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_reviews_order      ON reviews(order_id);
