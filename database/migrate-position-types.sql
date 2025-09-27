-- Migration to change position columns from INTEGER to DECIMAL for precise positioning
-- Run this in your Supabase SQL editor

BEGIN;

-- Change position_x and position_y from INTEGER to DECIMAL for subpixel precision
ALTER TABLE tasks 
  ALTER COLUMN position_x TYPE DECIMAL(10,2),
  ALTER COLUMN position_y TYPE DECIMAL(10,2);

COMMIT;

-- Verify the change
SELECT column_name, data_type, numeric_precision, numeric_scale 
FROM information_schema.columns 
WHERE table_name = 'tasks' 
AND column_name IN ('position_x', 'position_y');