-- Bucket público para imágenes/animaciones de ejercicios.
-- Escritura sólo service_role (autoría del catálogo es manual vía Studio).

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'exercise-media',
  'exercise-media',
  true,
  10485760,  -- 10 MB por archivo
  ARRAY[
    'image/png',
    'image/jpeg',
    'image/webp',
    'image/gif',
    'video/mp4',
    'video/webm'
  ]
)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "exercise_media_read_all" ON storage.objects;
CREATE POLICY "exercise_media_read_all" ON storage.objects
  FOR SELECT
  USING (bucket_id = 'exercise-media');
