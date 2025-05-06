-- Users table
CREATE TABLE users (
  id UUID REFERENCES auth.users ON DELETE CASCADE,
  email TEXT UNIQUE,
  full_name TEXT,
  username TEXT UNIQUE,
  bio TEXT,
  photo_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  followers_count INTEGER DEFAULT 0,
  following_count INTEGER DEFAULT 0,
  posts_count INTEGER DEFAULT 0,
  PRIMARY KEY (id)
);

-- Enable RLS (Row Level Security)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Locations table
CREATE TABLE locations (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  address TEXT,
  latitude FLOAT NOT NULL,
  longitude FLOAT NOT NULL,
  image_urls TEXT[] DEFAULT '{}',
  audio_url TEXT,
  visual_rating FLOAT DEFAULT 3.0,
  audio_rating FLOAT DEFAULT 3.0,
  categories TEXT[] DEFAULT '{}',
  creator_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  likes_count INTEGER DEFAULT 0,
  saves_count INTEGER DEFAULT 0
);

-- Enable RLS
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;

-- Saved locations table
CREATE TABLE saved_locations (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  location_id UUID REFERENCES locations(id) ON DELETE CASCADE,
  saved_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  UNIQUE(user_id, location_id)
);

-- Enable RLS
ALTER TABLE saved_locations ENABLE ROW LEVEL SECURITY;

-- Liked locations table
CREATE TABLE liked_locations (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  location_id UUID REFERENCES locations(id) ON DELETE CASCADE,
  liked_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  UNIQUE(user_id, location_id)
);

-- Enable RLS
ALTER TABLE liked_locations ENABLE ROW LEVEL SECURITY;

-- Follow relationships
CREATE TABLE follows (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  follower_id UUID REFERENCES users(id) ON DELETE CASCADE,
  following_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  UNIQUE(follower_id, following_id)
);

-- Enable RLS
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;

-- Users table policies
CREATE POLICY "Users are viewable by everyone" ON users
  FOR SELECT USING (true);

CREATE POLICY "Users can update their own record" ON users
  FOR UPDATE USING (auth.uid() = id);

-- Locations table policies
CREATE POLICY "Locations are viewable by everyone" ON locations
  FOR SELECT USING (true);

CREATE POLICY "Users can insert their own locations" ON locations
  FOR INSERT WITH CHECK (auth.uid()::text = creator_id::text);

CREATE POLICY "Users can update their own locations" ON locations
  FOR UPDATE USING (auth.uid()::text = creator_id::text);

CREATE POLICY "Users can delete their own locations" ON locations
  FOR DELETE USING (auth.uid()::text = creator_id::text);

-- Saved locations policies
CREATE POLICY "Users can view their own saved locations" ON saved_locations
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can save locations" ON saved_locations
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unsave their saved locations" ON saved_locations
  FOR DELETE USING (auth.uid() = user_id);

-- Liked locations policies
CREATE POLICY "Users can view their own liked locations" ON liked_locations
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can like locations" ON liked_locations
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unlike their liked locations" ON liked_locations
  FOR DELETE USING (auth.uid() = user_id);

-- Follows policies
CREATE POLICY "Anyone can view follow relationships" ON follows
  FOR SELECT USING (true);

CREATE POLICY "Users can follow others" ON follows
  FOR INSERT WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can unfollow others" ON follows
  FOR DELETE USING (auth.uid() = follower_id);

-- Function to handle user creation
CREATE OR REPLACE FUNCTION handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO users (id, email, full_name, username)
  VALUES (
    NEW.id, 
    NEW.email, 
    NEW.raw_user_meta_data->>'full_name', 
    NEW.raw_user_meta_data->>'username'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to automatically create user profile
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Updated function to handle user creation with more error handling
CREATE OR REPLACE FUNCTION handle_new_user() 
RETURNS TRIGGER AS $$
DECLARE
  username_val TEXT;
  fullname_val TEXT;
BEGIN
  -- Extract metadata with fallbacks
  fullname_val := COALESCE(NEW.raw_user_meta_data->>'full_name', 'User ' || substring(NEW.id::text, 1, 6));
  username_val := COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substring(NEW.id::text, 1, 6));
  
  -- Make sure username is unique by checking and appending a random suffix if needed
  WHILE EXISTS (SELECT 1 FROM users WHERE username = username_val) LOOP
    username_val := username_val || substring(gen_random_uuid()::text, 1, 4);
  END LOOP;
  
  -- Insert the user
  INSERT INTO users (id, email, full_name, username)
  VALUES (
    NEW.id, 
    NEW.email, 
    fullname_val,
    username_val
  );
  RETURN NEW;
EXCEPTION
  WHEN others THEN
    -- Log the error for debugging (will appear in Supabase logs)
    RAISE LOG 'Error in handle_new_user: %', SQLERRM;
    -- Still return NEW to not block the auth user creation
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Run this SQL in Supabase SQL Editor to fix missing user profiles and update triggers

-- 1. Update trigger function to be more robust
CREATE OR REPLACE FUNCTION handle_new_user() 
RETURNS TRIGGER AS $$
DECLARE
  username_val TEXT;
  fullname_val TEXT;
  existing_user RECORD;
BEGIN
  -- First check if a user with this ID already exists in users table
  SELECT * INTO existing_user FROM users WHERE id = NEW.id;
  
  IF existing_user.id IS NOT NULL THEN
    RAISE LOG 'User already exists in users table: %', NEW.id;
    RETURN NEW;
  END IF;
  
  -- Extract metadata with fallbacks
  fullname_val := COALESCE(NEW.raw_user_meta_data->>'full_name', 'User ' || substring(NEW.id::text, 1, 6));
  username_val := COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substring(NEW.id::text, 1, 6));
  
  -- Make sure username is unique by checking and appending a random suffix if needed
  WHILE EXISTS (SELECT 1 FROM users WHERE username = username_val) LOOP
    username_val := username_val || substring(gen_random_uuid()::text, 1, 4);
  END LOOP;
  
  BEGIN
    -- Insert the user with error handling
    INSERT INTO users (id, email, full_name, username)
    VALUES (
      NEW.id, 
      NEW.email, 
      fullname_val,
      username_val
    );
    
    RAISE LOG 'New user created successfully: ID=%, Email=%, Username=%', NEW.id, NEW.email, username_val;
  EXCEPTION
    WHEN others THEN
      RAISE LOG 'Error creating user profile in trigger: %', SQLERRM;
  END;
  
  RETURN NEW;
EXCEPTION
  WHEN others THEN
    RAISE LOG 'Error in handle_new_user trigger: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Fix existing users who have auth accounts but no profiles
DO $$
DECLARE
  auth_user RECORD;
  username_val TEXT;
  fullname_val TEXT;
  unique_username BOOLEAN;
  attempt INT;
BEGIN
  -- Loop through auth users that don't have corresponding profiles
  FOR auth_user IN 
    SELECT au.id, au.email, au.raw_user_meta_data 
    FROM auth.users au 
    LEFT JOIN users u ON au.id = u.id 
    WHERE u.id IS NULL
  LOOP
    -- Log which user we're processing
    RAISE NOTICE 'Processing auth user: % with email %', auth_user.id, auth_user.email;
    
    -- Extract metadata with fallbacks
    fullname_val := COALESCE(auth_user.raw_user_meta_data->>'full_name', 'User ' || substring(auth_user.id::text, 1, 6));
    username_val := COALESCE(auth_user.raw_user_meta_data->>'username', 'user_' || substring(auth_user.id::text, 1, 6));
    
    -- Make sure username is unique
    unique_username := FALSE;
    attempt := 0;
    
    WHILE NOT unique_username AND attempt < 5 LOOP
      IF NOT EXISTS (SELECT 1 FROM users WHERE username = username_val) THEN
        unique_username := TRUE;
      ELSE
        username_val := username_val || substring(gen_random_uuid()::text, 1, 4);
        attempt := attempt + 1;
      END IF;
    END LOOP;
    
    BEGIN
      -- Insert the user
      INSERT INTO users (
        id, 
        email, 
        full_name, 
        username,
        created_at
      )
      VALUES (
        auth_user.id, 
        auth_user.email, 
        fullname_val,
        username_val,
        NOW()
      );
      
      RAISE NOTICE 'Created missing user profile: ID=%, Email=%, Username=%', 
        auth_user.id, auth_user.email, username_val;
    EXCEPTION
      WHEN others THEN
        RAISE NOTICE 'Error creating user profile: %', SQLERRM;
    END;
  END LOOP;
END;
$$;

-- 3. Count how many profiles were missing and report
SELECT 
  (SELECT COUNT(*) FROM auth.users) AS auth_users_count,
  (SELECT COUNT(*) FROM users) AS profile_users_count,
  (SELECT COUNT(*) FROM auth.users) - (SELECT COUNT(*) FROM users) AS missing_profiles_count;

-- File to run in Supabase SQL Editor to create the necessary database functions

-- Function to increment likes count
CREATE OR REPLACE FUNCTION increment_likes_count(location_id_param UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE locations
  SET likes_count = likes_count + 1
  WHERE id = location_id_param;
END;
$$;

-- Function to decrement likes count
CREATE OR REPLACE FUNCTION decrement_likes_count(location_id_param UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE locations
  SET likes_count = GREATEST(0, likes_count - 1)
  WHERE id = location_id_param;
END;
$$;

-- Function to increment saves count
CREATE OR REPLACE FUNCTION increment_saves_count(location_id_param UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE locations
  SET saves_count = saves_count + 1
  WHERE id = location_id_param;
END;
$$;

-- Function to decrement saves count
CREATE OR REPLACE FUNCTION decrement_saves_count(location_id_param UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE locations
  SET saves_count = GREATEST(0, saves_count - 1)
  WHERE id = location_id_param;
END;
$$;

-- Add unique constraint to ensure a user can only save a location once
DO $$ 
BEGIN
  -- Check if the constraint already exists
  IF NOT EXISTS (
    SELECT 1 
    FROM pg_constraint 
    WHERE conname = 'unique_user_saved_location'
  ) THEN
    ALTER TABLE saved_locations
    ADD CONSTRAINT unique_user_saved_location
    UNIQUE (user_id, location_id);
  END IF;
END $$;

-- Add unique constraint to ensure a user can only like a location once
DO $$ 
BEGIN
  -- Check if the constraint already exists
  IF NOT EXISTS (
    SELECT 1 
    FROM pg_constraint 
    WHERE conname = 'unique_user_liked_location'
  ) THEN
    ALTER TABLE liked_locations
    ADD CONSTRAINT unique_user_liked_location
    UNIQUE (user_id, location_id);
  END IF;
END $$;

-- File to run in Supabase SQL Editor to create the necessary RPC functions that bypass RLS

-- Function to check if a user has liked a location
CREATE OR REPLACE FUNCTION check_if_liked(user_id_param UUID, location_id_param UUID)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER -- This bypasses RLS
AS $$
DECLARE
  exists_record boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 
    FROM liked_locations 
    WHERE user_id = user_id_param AND location_id = location_id_param
  ) INTO exists_record;
  
  RETURN exists_record;
END;
$$;

-- Function to check if a user has saved a location
CREATE OR REPLACE FUNCTION check_if_saved(user_id_param UUID, location_id_param UUID)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER -- This bypasses RLS
AS $$
DECLARE
  exists_record boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 
    FROM saved_locations 
    WHERE user_id = user_id_param AND location_id = location_id_param
  ) INTO exists_record;
  
  RETURN exists_record;
END;
$$;

-- Update the increment_likes_count function to use SECURITY DEFINER
CREATE OR REPLACE FUNCTION increment_likes_count(location_id_param UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- This bypasses RLS
AS $$
BEGIN
  UPDATE locations
  SET likes_count = likes_count + 1
  WHERE id = location_id_param;
END;
$$;

-- Update the decrement_likes_count function to use SECURITY DEFINER
CREATE OR REPLACE FUNCTION decrement_likes_count(location_id_param UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- This bypasses RLS
AS $$
BEGIN
  UPDATE locations
  SET likes_count = GREATEST(0, likes_count - 1)
  WHERE id = location_id_param;
END;
$$;

-- Update the increment_saves_count function to use SECURITY DEFINER
CREATE OR REPLACE FUNCTION increment_saves_count(location_id_param UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- This bypasses RLS
AS $$
BEGIN
  UPDATE locations
  SET saves_count = saves_count + 1
  WHERE id = location_id_param;
END;
$$;

-- Update the decrement_saves_count function to use SECURITY DEFINER
CREATE OR REPLACE FUNCTION decrement_saves_count(location_id_param UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- This bypasses RLS
AS $$
BEGIN
  UPDATE locations
  SET saves_count = GREATEST(0, saves_count - 1)
  WHERE id = location_id_param;
END;
$$;

-- Function to directly insert a like record (bypassing RLS)
CREATE OR REPLACE FUNCTION insert_like(user_id_param UUID, location_id_param UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- This bypasses RLS
AS $$
BEGIN
  INSERT INTO liked_locations (user_id, location_id, liked_at)
  VALUES (user_id_param, location_id_param, NOW())
  ON CONFLICT (user_id, location_id) DO NOTHING;
END;
$$;

-- Function to directly delete a like record (bypassing RLS)
CREATE OR REPLACE FUNCTION delete_like(user_id_param UUID, location_id_param UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- This bypasses RLS
AS $$
BEGIN
  DELETE FROM liked_locations
  WHERE user_id = user_id_param AND location_id = location_id_param;
END;
$$;

-- Function to directly insert a save record (bypassing RLS)
CREATE OR REPLACE FUNCTION insert_save(user_id_param UUID, location_id_param UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- This bypasses RLS
AS $$
BEGIN
  INSERT INTO saved_locations (user_id, location_id, saved_at)
  VALUES (user_id_param, location_id_param, NOW())
  ON CONFLICT (user_id, location_id) DO NOTHING;
END;
$$;

-- Function to directly delete a save record (bypassing RLS)
CREATE OR REPLACE FUNCTION delete_save(user_id_param UUID, location_id_param UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- This bypasses RLS
AS $$
BEGIN
  DELETE FROM saved_locations
  WHERE user_id = user_id_param AND location_id = location_id_param;
END;
$$;

-- Run this SQL in your Supabase SQL Editor to fix user authentication issues

-- 1. First, let's create a more robust trigger for user creation
CREATE OR REPLACE FUNCTION handle_new_user() 
RETURNS TRIGGER AS $$
DECLARE
  username_val TEXT;
  fullname_val TEXT;
  exists_record BOOLEAN;
BEGIN
  -- First check if user already exists in the users table
  SELECT EXISTS (
    SELECT 1 FROM users WHERE id = NEW.id
  ) INTO exists_record;
  
  -- If user already exists, we don't need to do anything
  IF exists_record THEN
    RAISE LOG 'User % already exists in users table', NEW.id;
    RETURN NEW;
  END IF;
  
  -- Extract metadata with fallbacks
  fullname_val := COALESCE(NEW.raw_user_meta_data->>'full_name', 'User ' || substring(NEW.id::text, 1, 6));
  username_val := COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substring(NEW.id::text, 1, 6));
  
  -- Make sure username is unique
  WHILE EXISTS (SELECT 1 FROM users WHERE username = username_val) LOOP
    username_val := username_val || substring(gen_random_uuid()::text, 1, 4);
  END LOOP;
  
  -- Insert new user with explicit created_at
  BEGIN
    INSERT INTO users (
      id, 
      email, 
      full_name, 
      username,
      created_at
    ) VALUES (
      NEW.id, 
      NEW.email, 
      fullname_val,
      username_val,
      NOW()
    );
    
    RAISE LOG 'Created user profile: ID=%, Email=%, Username=%', 
      NEW.id, NEW.email, username_val;
  EXCEPTION
    WHEN others THEN
      RAISE LOG 'Error creating user profile: %', SQLERRM;
  END;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Make sure the trigger is correctly set up
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- 2. Create a function to fix missing users
CREATE OR REPLACE FUNCTION create_missing_user_profile(user_id_param UUID, email_param TEXT) 
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  exists_record BOOLEAN;
  username_val TEXT;
  fullname_val TEXT;
  user_metadata JSONB;
BEGIN
  -- Check if user already exists
  SELECT EXISTS (
    SELECT 1 FROM users WHERE id = user_id_param
  ) INTO exists_record;
  
  -- If user already exists, return true (success)
  IF exists_record THEN
    RAISE LOG 'User % already exists in users table', user_id_param;
    RETURN TRUE;
  END IF;
  
  -- Get user metadata from auth.users
  SELECT raw_user_meta_data INTO user_metadata 
  FROM auth.users 
  WHERE id = user_id_param;
  
  -- Extract metadata with fallbacks
  fullname_val := COALESCE(user_metadata->>'full_name', 'User ' || substring(user_id_param::text, 1, 6));
  username_val := COALESCE(user_metadata->>'username', 'user_' || substring(user_id_param::text, 1, 6));
  
  -- Make sure username is unique
  WHILE EXISTS (SELECT 1 FROM users WHERE username = username_val) LOOP
    username_val := username_val || substring(gen_random_uuid()::text, 1, 4);
  END LOOP;
  
  -- Insert new user
  BEGIN
    INSERT INTO users (
      id, 
      email, 
      full_name, 
      username,
      created_at
    ) VALUES (
      user_id_param, 
      email_param, 
      fullname_val,
      username_val,
      NOW()
    );
    
    RAISE LOG 'Created missing user profile: ID=%, Email=%, Username=%', 
      user_id_param, email_param, username_val;
    
    RETURN TRUE;
  EXCEPTION
    WHEN others THEN
      RAISE LOG 'Error creating missing user profile: %', SQLERRM;
      RETURN FALSE;
  END;
END;
$$;

-- 3. Make sure the RPC functions for like/save are correctly created
-- Function to check if a user has liked a location
CREATE OR REPLACE FUNCTION check_if_liked(user_id_param UUID, location_id_param UUID)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER -- This bypasses RLS
AS $$
DECLARE
  exists_record boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 
    FROM liked_locations 
    WHERE user_id = user_id_param AND location_id = location_id_param
  ) INTO exists_record;
  
  RETURN exists_record;
END;
$$;

-- Function to check if a user has saved a location
CREATE OR REPLACE FUNCTION check_if_saved(user_id_param UUID, location_id_param UUID)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER -- This bypasses RLS
AS $$
DECLARE
  exists_record boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 
    FROM saved_locations 
    WHERE user_id = user_id_param AND location_id = location_id_param
  ) INTO exists_record;
  
  RETURN exists_record;
END;
$$;

-- Function to increment likes count
CREATE OR REPLACE FUNCTION increment_likes_count(location_id_param UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- This bypasses RLS
AS $$
BEGIN
  UPDATE locations
  SET likes_count = likes_count + 1
  WHERE id = location_id_param;
END;
$$;

-- Function to decrement likes count
CREATE OR REPLACE FUNCTION decrement_likes_count(location_id_param UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- This bypasses RLS
AS $$
BEGIN
  UPDATE locations
  SET likes_count = GREATEST(0, likes_count - 1)
  WHERE id = location_id_param;
END;
$$;

-- Function to increment saves count
CREATE OR REPLACE FUNCTION increment_saves_count(location_id_param UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- This bypasses RLS
AS $$
BEGIN
  UPDATE locations
  SET saves_count = saves_count + 1
  WHERE id = location_id_param;
END;
$$;

-- Function to decrement saves count
CREATE OR REPLACE FUNCTION decrement_saves_count(location_id_param UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- This bypasses RLS
AS $$
BEGIN
  UPDATE locations
  SET saves_count = GREATEST(0, saves_count - 1)
  WHERE id = location_id_param;
END;
$$;

-- Function to directly insert a like record (bypassing RLS)
CREATE OR REPLACE FUNCTION insert_like(user_id_param UUID, location_id_param UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- This bypasses RLS
AS $$
BEGIN
  INSERT INTO liked_locations (user_id, location_id, liked_at)
  VALUES (user_id_param, location_id_param, NOW())
  ON CONFLICT (user_id, location_id) DO NOTHING;
END;
$$;

-- Function to directly delete a like record (bypassing RLS)
CREATE OR REPLACE FUNCTION delete_like(user_id_param UUID, location_id_param UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- This bypasses RLS
AS $$
BEGIN
  DELETE FROM liked_locations
  WHERE user_id = user_id_param AND location_id = location_id_param;
END;
$$;

-- Function to directly insert a save record (bypassing RLS)
CREATE OR REPLACE FUNCTION insert_save(user_id_param UUID, location_id_param UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- This bypasses RLS
AS $$
BEGIN
  INSERT INTO saved_locations (user_id, location_id, saved_at)
  VALUES (user_id_param, location_id_param, NOW())
  ON CONFLICT (user_id, location_id) DO NOTHING;
END;
$$;

-- Function to directly delete a save record (bypassing RLS)
CREATE OR REPLACE FUNCTION delete_save(user_id_param UUID, location_id_param UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- This bypasses RLS
AS $$
BEGIN
  DELETE FROM saved_locations
  WHERE user_id = user_id_param AND location_id = location_id_param;
END;
$$;

-- 4. Add additional RLS policy to allow users to view locations
CREATE POLICY "Users can view all locations" ON locations
  FOR SELECT
  USING (true);