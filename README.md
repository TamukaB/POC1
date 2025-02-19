For this project the goal was to add a CPUID to be a part of the GUID registration flow that is also stored in the DB upon user registration.
As however a CPUID cannot be retrieved for web browser RoR based applications due to security restrictions, fingerprintJS was used as a work around to mimic the uniqueness of a CPUID. 
