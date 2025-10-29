# Feed Creation Restriction for Khadems

## Summary
Updated the feed creation functionality to restrict khadems to only create feeds for their own assigned class, while super admins can still create feeds for all classes.

## Changes Made

### Frontend Changes (Flutter App)
**File**: `SaintDemianaChildren/lib/features/feed/view/widget/add_feed_dialog.dart`

#### 1. Added Role-Based Class Filtering
- Khadems now only see their own assigned class in the class selector
- Super admins continue to see all classes in a dropdown

```dart
// Filter classes based on user role
if (currentUser?.role == UserRole.khadem && currentUser?.classId != null) {
  // Khadem can only see their own class
  _classes = classes.where((c) => c.id == currentUser!.classId).toList();
} else {
  // Super admin can see all classes
  _classes = classes;
}
```

#### 2. Improved UI/UX
- **For Khadems**: Shows a read-only field displaying their class name with an icon
- **For Super Admins**: Shows a dropdown to select from all available classes
- Added validation to check if khadem has a class assigned

#### 3. Added Validation
- Checks if khadem has a class assigned before allowing feed creation
- Shows user-friendly error message in Arabic: "لم يتم تعيين فصل لك. الرجاء التواصل مع الإدارة."

### Backend Validation (Already in Place)
**File**: `SaintDemianaChildren-BE/src/application/services/FeedService.js`

The backend already has proper security validation:

```javascript
async _canManageFeed(user, classId) {
  // Super admin and admin can manage any feed
  if (user.role === 'super_admin' || user.role === 'admin') {
    return true;
  }

  // Khadem can manage feeds only in their assigned classes
  if (user.role === 'khadem') {
    const membership = await ClassMembership.findOne({
      where: {
        userId: user.id,
        classId: classId,
        role: 'khadem',
        isActive: true,
      },
    });
    return !!membership;
  }

  return false;
}
```

## Security
✅ **Frontend Validation**: Filters available classes based on user role
✅ **Backend Validation**: Verifies class membership before allowing feed creation
✅ **Protection Against**: Malicious users cannot bypass frontend restrictions via API calls

## User Experience
### For Khadems
- Cleaner interface showing only their class
- No confusing dropdown with classes they can't post to
- Clear visual indication of their assigned class
- Better error messaging if no class is assigned

### For Super Admins
- Unchanged functionality
- Can still create feeds for any class
- Full control over all classes

## Testing Recommendations
1. Test as a khadem with an assigned class
2. Test as a khadem without an assigned class (should show error)
3. Test as a super admin (should see all classes)
4. Try to manually call the API with a different classId as a khadem (should be rejected by backend)

## Future Enhancements
Consider adding:
- Ability for khadems to see which class they're assigned to in their profile
- Notification when a khadem is assigned to a new class
- Admin interface to manage khadem-class assignments

