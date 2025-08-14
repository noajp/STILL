-- ======================================================================
-- Migration: 20250101_000013_add_public_key_to_profiles.sql
-- Purpose: Add public key for E2E encryption support
-- Dependencies: public.profiles
-- ======================================================================

ALTER TABLE profiles ADD COLUMN public_key TEXT;
