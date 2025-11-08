/*
  # E-commerce Platform Schema

  ## Overview
  Creates a complete e-commerce database schema for a PC components and electronics shopping site.

  ## New Tables
  
  ### 1. `products`
  - `id` (uuid, primary key) - Unique product identifier
  - `name` (text) - Product name
  - `description` (text) - Detailed product description
  - `price` (numeric) - Product price
  - `category` (text) - Product category (monitors, graphics-cards, processors, etc)
  - `brand` (text) - Manufacturer/brand name
  - `image_url` (text) - Product image URL
  - `stock` (integer) - Available inventory count
  - `specs` (jsonb) - Technical specifications as JSON
  - `rating` (numeric) - Average customer rating (0-5)
  - `created_at` (timestamptz) - Record creation timestamp

  ### 2. `cart_items`
  - `id` (uuid, primary key) - Unique cart item identifier
  - `user_id` (uuid) - Reference to authenticated user
  - `product_id` (uuid) - Reference to product
  - `quantity` (integer) - Number of items
  - `created_at` (timestamptz) - When item was added to cart

  ### 3. `orders`
  - `id` (uuid, primary key) - Unique order identifier
  - `user_id` (uuid) - Reference to authenticated user
  - `total_amount` (numeric) - Total order cost
  - `status` (text) - Order status (pending, processing, shipped, delivered)
  - `shipping_address` (jsonb) - Shipping details as JSON
  - `created_at` (timestamptz) - Order creation timestamp

  ### 4. `order_items`
  - `id` (uuid, primary key) - Unique order item identifier
  - `order_id` (uuid) - Reference to order
  - `product_id` (uuid) - Reference to product
  - `quantity` (integer) - Number of items ordered
  - `price_at_purchase` (numeric) - Price at time of purchase
  - `created_at` (timestamptz) - Record creation timestamp

  ## Security
  
  ### Row Level Security (RLS)
  - All tables have RLS enabled
  - Products are publicly readable
  - Cart items are only accessible by the owner
  - Orders and order items are only accessible by the owner
  
  ### Policies
  - Public read access for products
  - Authenticated users can manage their own cart items
  - Authenticated users can create and view their own orders
  - Authenticated users can view their own order items
*/

-- Create products table
CREATE TABLE IF NOT EXISTS products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text NOT NULL,
  price numeric NOT NULL CHECK (price >= 0),
  category text NOT NULL,
  brand text NOT NULL,
  image_url text NOT NULL,
  stock integer NOT NULL DEFAULT 0 CHECK (stock >= 0),
  specs jsonb DEFAULT '{}'::jsonb,
  rating numeric DEFAULT 0 CHECK (rating >= 0 AND rating <= 5),
  created_at timestamptz DEFAULT now()
);

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Products are publicly readable"
  ON products FOR SELECT
  TO anon, authenticated
  USING (true);

-- Create cart_items table
CREATE TABLE IF NOT EXISTS cart_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  product_id uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  quantity integer NOT NULL DEFAULT 1 CHECK (quantity > 0),
  created_at timestamptz DEFAULT now()
);

ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own cart items"
  ON cart_items FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own cart items"
  ON cart_items FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own cart items"
  ON cart_items FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own cart items"
  ON cart_items FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Create orders table
CREATE TABLE IF NOT EXISTS orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  total_amount numeric NOT NULL CHECK (total_amount >= 0),
  status text NOT NULL DEFAULT 'pending',
  shipping_address jsonb NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own orders"
  ON orders FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own orders"
  ON orders FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Create order_items table
CREATE TABLE IF NOT EXISTS order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES products(id),
  quantity integer NOT NULL CHECK (quantity > 0),
  price_at_purchase numeric NOT NULL CHECK (price_at_purchase >= 0),
  created_at timestamptz DEFAULT now()
);

ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own order items"
  ON order_items FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
      AND orders.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create own order items"
  ON order_items FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
      AND orders.user_id = auth.uid()
    )
  );

-- Insert sample products
INSERT INTO products (name, description, price, category, brand, image_url, stock, specs, rating) VALUES
('UltraWide 34" Gaming Monitor', 'Stunning 3440x1440 resolution with 144Hz refresh rate and G-SYNC support', 599.99, 'monitors', 'TechVision', 'https://images.pexels.com/photos/777001/pexels-photo-777001.jpeg', 15, '{"resolution": "3440x1440", "refresh_rate": "144Hz", "panel_type": "IPS", "response_time": "1ms"}'::jsonb, 4.7),
('RTX 4080 Graphics Card', 'High-performance GPU with 16GB GDDR6X memory, perfect for 4K gaming and content creation', 1199.99, 'graphics-cards', 'NVIDIA', 'https://images.pexels.com/photos/2582928/pexels-photo-2582928.jpeg', 8, '{"memory": "16GB GDDR6X", "boost_clock": "2.51 GHz", "cuda_cores": "9728"}'::jsonb, 4.9),
('Intel Core i9-14900K', '24-core processor with 6.0 GHz max turbo frequency for extreme performance', 589.99, 'processors', 'Intel', 'https://images.pexels.com/photos/2582937/pexels-photo-2582937.jpeg', 12, '{"cores": "24", "threads": "32", "base_clock": "3.2 GHz", "max_turbo": "6.0 GHz"}'::jsonb, 4.8),
('32GB DDR5 RAM Kit', 'High-speed 6000MHz memory kit for demanding applications and gaming', 159.99, 'memory', 'Corsair', 'https://images.pexels.com/photos/2588757/pexels-photo-2588757.jpeg', 25, '{"capacity": "32GB", "speed": "6000MHz", "latency": "CL36", "modules": "2x16GB"}'::jsonb, 4.6),
('2TB NVMe SSD', 'Lightning-fast PCIe Gen4 storage with 7000MB/s read speeds', 189.99, 'storage', 'Samsung', 'https://images.pexels.com/photos/2582935/pexels-photo-2582935.jpeg', 30, '{"capacity": "2TB", "interface": "PCIe Gen4", "read_speed": "7000 MB/s", "write_speed": "5000 MB/s"}'::jsonb, 4.8),
('Gaming Mechanical Keyboard', 'RGB backlit mechanical keyboard with Cherry MX switches', 129.99, 'peripherals', 'Razer', 'https://images.pexels.com/photos/1714208/pexels-photo-1714208.jpeg', 40, '{"switch_type": "Cherry MX Red", "backlight": "RGB", "connectivity": "USB-C"}'::jsonb, 4.5),
('Wireless Gaming Mouse', 'High-precision wireless mouse with 25K DPI sensor', 79.99, 'peripherals', 'Logitech', 'https://images.pexels.com/photos/2115257/pexels-photo-2115257.jpeg', 50, '{"dpi": "25600", "battery_life": "70 hours", "buttons": "8"}'::jsonb, 4.7),
('850W Modular PSU', '80+ Gold certified power supply with fully modular cables', 149.99, 'power-supplies', 'EVGA', 'https://images.pexels.com/photos/2582930/pexels-photo-2582930.jpeg', 20, '{"wattage": "850W", "efficiency": "80+ Gold", "modular": "Full"}'::jsonb, 4.8),
('Mid-Tower Gaming Case', 'Tempered glass case with excellent airflow and RGB lighting', 119.99, 'cases', 'NZXT', 'https://images.pexels.com/photos/2582934/pexels-photo-2582934.jpeg', 18, '{"form_factor": "Mid Tower", "material": "Tempered Glass", "fans_included": "3"}'::jsonb, 4.6),
('27" 4K IPS Monitor', 'Professional-grade 4K monitor with 99% sRGB color accuracy', 449.99, 'monitors', 'Dell', 'https://images.pexels.com/photos/1714208/pexels-photo-1714208.jpeg', 22, '{"resolution": "3840x2160", "refresh_rate": "60Hz", "panel_type": "IPS", "color_accuracy": "99% sRGB"}'::jsonb, 4.7);
