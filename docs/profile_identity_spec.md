# MANOX Profile Identity Specification

## Edit Profile

The profile editor should support:
- profile photo
- display name and username
- bio
- country
- location
- profession/category
- website and external links
- creator identity
- privacy controls for public profile fields

## Profession choices

Creator, Farmer, Doctor, Lawyer, Police, Teacher, Student, Business, Engineer, Artist, Athlete, Freelancer, Other.

## Public Profile

When a user opens another person's profile, show the fields that person has made public: name, username, photo, bio, country, profession/category, links, creator identity, and posts/content.

## Product requirements

- Keep MANOX branding and existing navigation intact.
- Do not expose private fields.
- Keep the model extensible for profession-specific creator features.
- Profile fields must be suitable for future Supabase persistence and RLS policies.
