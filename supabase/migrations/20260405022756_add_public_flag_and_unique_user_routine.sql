-- Add is_public column to routines
ALTER TABLE public.routines
ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT FALSE;

-- Enforce single active routine per user in user_routines
-- First, drop the old primary key if it was a composite of (user_id, routine_id)
-- based on our inspection, it was the primary key.
ALTER TABLE public.user_routines DROP CONSTRAINT IF EXISTS user_routines_pkey;

-- Create a new primary key that is just user_id to enforce 1-routine-per-user
-- If we want to allow primary key to be (user_id), we do:
ALTER TABLE public.user_routines ADD PRIMARY KEY (user_id);

-- Or alternatively, add a UNIQUE constraint if we wanted to keeps (user_id, routine_id) as PK
-- But making user_id the PK is cleaner for "Single assigned routine".
