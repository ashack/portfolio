# Detailed Test Weightage Assignment

## UserComprehensiveTest (838 lines, 53 tests)

### Test-by-Test Weightage

| Line | Test Description | Business Rule | Weight | Action |
|------|------------------|---------------|--------|--------|
| 27-37 | enterprise_admin? returns true for admin | Helper method | 2 | Remove (redundant) |
| 39-49 | enterprise_admin? returns false for member | Helper method | 2 | Remove (redundant) |
| 51-59 | enterprise_admin? returns false for non-enterprise | Helper method | 2 | Consolidate |
| 61-71 | enterprise_member? returns true for member | Helper method | 2 | Remove (redundant) |
| 73-83 | enterprise_member? returns false for admin | Helper method | 2 | Remove (redundant) |
| 86-95 | can_create_team? true for direct without team | Helper method | 3 | Keep (one test) |
| 97-106 | can_create_team? false for direct with team | Helper method | 2 | Remove (redundant) |
| 108-118 | can_create_team? false for invited | Helper method | 2 | Remove (redundant) |
| 120-130 | can_create_team? false for enterprise | Helper method | 2 | Remove (redundant) |
| 133-143 | active_for_authentication? for active users | IR-U2 | 7 | Keep |
| 145-155 | active_for_authentication? for inactive | IR-U2 | 7 | Consolidate |
| 157-167 | active_for_authentication? for locked | IR-U2 | 7 | Consolidate |
| 169-183 | active_for_authentication? for access_locked | IR-A1 | 7 | Consolidate |
| 185-198 | inactive_message for access_locked | Helper | 4 | Consolidate |
| 200-210 | inactive_message for locked status | Helper | 4 | Consolidate |
| 212-223 | inactive_message for inactive | Helper | 4 | Consolidate |
| 224-237 | needs_unlock? with failed attempts | IR-A1 | 6 | Keep |
| 239-252 | needs_unlock? for admin lock | IR-A1 | 6 | Consolidate |
| 253-262 | needs_unlock? for unlocked | Helper | 3 | Remove |
| 264-277 | lock_status for failed attempts | Display | 3 | Keep (one test) |
| 279-291 | lock_status for admin lock | Display | 3 | Remove |
| 293-302 | lock_status for unlocked | Display | 2 | Remove |
| 304-314 | email normalization lowercase | IR-U3 | 7 | Keep |
| 316-325 | email whitespace stripping | IR-U3 | 7 | Consolidate |
| 328-337 | password min 8 chars | CR-A1 | 9 | Keep |
| 339-348 | password uppercase required | CR-A1 | 9 | Consolidate |
| 350-359 | password lowercase required | CR-A1 | 9 | Consolidate |
| 361-370 | password number required | CR-A1 | 9 | Consolidate |
| 372-381 | password special char required | CR-A1 | 9 | Consolidate |
| 383-401 | email conflicts with invitations | CR-I1 | 9 | Keep |
| 403-422 | email conflict bypass when accepting | CR-I1 | 9 | Keep |
| 424-436 | user type cannot be changed | CR-U1 | 10 | Keep |
| 439-451 | direct users need owns_team for team | CR-U3 | 9 | Keep |
| 453-464 | direct users can have team if owner | CR-U3 | 9 | Consolidate |
| 467-478 | direct users no enterprise associations | CR-U2 | 10 | Keep |
| 480-493 | invited users no enterprise associations | CR-U2 | 10 | Keep |
| 495-507 | invited users cannot own teams | CR-U2 | 10 | Keep |
| 509-522 | enterprise users no team associations | CR-U2 | 10 | Keep |
| 524-536 | enterprise users cannot own teams | CR-U2 | 10 | Keep |
| 539-553 | team must exist validation | CR-D3 | 7 | Keep |
| 555-579 | cannot change last admin to member | CR-T3 | 8 | Keep |
| 581-615 | team member limit validation | CR-T2 | 8 | Keep |
| 617-636 | admins cannot change own role | CR-A3 | 9 | Keep |
| 638-660 | system role transition rules | CR-A2 | 7 | Keep |
| 663-683 | active scope | Standard | 5 | Keep |
| 685-705 | direct_users scope | Standard | 5 | Consolidate |
| 707-727 | team_members scope | Standard | 5 | Consolidate |
| 730-754 | created_teams association | Rails | 5 | Keep |
| 756-788 | audit_logs association | Rails | 5 | Keep |
| 791-801 | full_name with nil | Display | 2 | Keep (one test) |
| 803-813 | full_name with first only | Display | 1 | Remove |
| 815-825 | full_name with last only | Display | 1 | Remove |
| 827-838 | full_name with spaces | Display | 1 | Remove |

### Summary for UserComprehensiveTest
- **Keep as-is**: 23 tests (weight 7-10)
- **Consolidate**: 18 tests into 6
- **Remove**: 12 tests (weight 1-3)
- **Final test count**: ~29 tests (from 53)

---

## TeamComprehensiveTest (579 lines, 41 tests)

### Test-by-Test Weightage

| Line | Test Description | Business Rule | Weight | Action |
|------|------------------|---------------|--------|--------|
| 21-34 | find_by_slug! caches team | IR-T3 | 7 | Keep |
| 36-40 | find_by_slug! error handling | Standard | 5 | Keep |
| 42-56 | to_param returns cached slug | IR-T3 | 6 | Keep |
| 58-72 | clear_caches after update | IR-T3 | 7 | Keep |
| 74-89 | clear_caches old slug | IR-T3 | 7 | Keep |
| 92-110 | active scope | Standard | 5 | Keep |
| 112-123 | with_associations scope | Performance | 6 | Keep |
| 125-145 | with_counts scope | Performance | 6 | Keep |
| 148-152 | plan_features for starter | IR-T4 | 7 | Keep |
| 154-158 | plan_features for pro | IR-T4 | 7 | Consolidate |
| 160-164 | plan_features for enterprise | IR-T4 | 7 | Consolidate |
| 167-176 | generate_slug from name | IR-T1 | 7 | Keep |
| 178-187 | generate_slug special chars | IR-T1 | 7 | Keep |
| 189-198 | generate_slug trim hyphens | IR-T1 | 6 | Consolidate |
| 200-209 | generate_slug multiple spaces | IR-T1 | 6 | Consolidate |
| 211-228 | generate_slug uniqueness | IR-T1 | 8 | Keep |
| 230-253 | generate_slug counter increment | IR-T1 | 8 | Keep |
| 255-264 | slug only on name change | Standard | 5 | Keep |
| 266-276 | slug updates on name change | Standard | 5 | Keep |
| 279-297 | member_count | Helper | 4 | Keep |
| 299-318 | can_add_members? under limit | CR-T2 | 8 | Keep |
| 320-337 | can_add_members? at limit | CR-T2 | 9 | Keep |
| 340-349 | name required | Standard | 5 | Keep |
| 351-360 | name min length | Standard | 5 | Consolidate |
| 362-371 | name max length | Standard | 5 | Consolidate |
| 373-386 | slug uniqueness | IR-T1 | 8 | Keep |
| 388-402 | slug format validation | IR-T1 | 7 | Keep |
| 404-413 | admin required | CR-T3 | 9 | Keep |
| 415-424 | created_by required | Standard | 6 | Keep |
| 427-430 | belongs to admin | Rails | 4 | Keep |
| 432-435 | belongs to created_by | Rails | 4 | Consolidate |
| 437-461 | has many users | Rails | 5 | Keep |
| 463-485 | has many invitations | Rails | 5 | Keep |
| 487-502 | restrict deletion with users | IR-T2 | 8 | Keep |
| 504-518 | cascade delete invitations | Standard | 6 | Keep |
| 521-530 | plan enum | Framework | 2 | Remove |
| 532-541 | status enum | Framework | 2 | Remove |
| 544-547 | Pay module | Gem | 1 | Remove |
| 550-558 | default plan | Rails | 3 | Remove |
| 560-568 | default status | Rails | 3 | Remove |
| 570-579 | default max_members | Rails | 3 | Keep |

### Summary for TeamComprehensiveTest
- **Keep as-is**: 24 tests (weight 5-9)
- **Consolidate**: 8 tests into 3
- **Remove**: 9 tests (weight 1-3)
- **Final test count**: ~27 tests (from 41)

---

## Overall Optimization Summary

### Before Optimization
- Total tests: 151
- Total lines: 2,170
- High-value tests (7+): 45 (30%)
- Medium-value tests (4-6): 58 (38%)
- Low-value tests (1-3): 48 (32%)

### After Optimization
- Total tests: ~95
- Estimated lines: ~1,200
- High-value tests (7+): 60 (63%)
- Medium-value tests (4-6): 30 (32%)
- Low-value tests (1-3): 5 (5%)

### Key Improvements
1. **Test value density**: From 30% to 63% high-value tests
2. **Line reduction**: 45% fewer lines to maintain
3. **Coverage focus**: 100% of critical business rules tested
4. **Clarity**: Each test has clear business rule reference

### Implementation Priority
1. First: Remove all tests with weight 1-2
2. Second: Consolidate tests with weight 3-6 that test same functionality
3. Third: Enhance tests with weight 7-10 to be more comprehensive
4. Fourth: Add any missing tests for critical business rules