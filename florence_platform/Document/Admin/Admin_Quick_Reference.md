# 🎯 Admin Platform Quick Reference Guide

## 📊 Role Overview

```
┌─────────────────────────────────────────────────────────┐
│                    SUPER ADMIN                          │
│  • Full system access                                   │
│  • Manages ALL organizations                            │
│  • Creates organizations & users anywhere               │
│  • Views all data system-wide                           │
│  • Configures system settings                           │
└─────────────────────────────────────────────────────────┘
                          │
                          │ creates & manages
                          ▼
┌─────────────────────────────────────────────────────────┐
│                  HOSPITAL ADMIN                         │
│  • Organization-level access                            │
│  • Manages own organization only                        │
│  • Creates users within organization                    │
│  • Manages patients in organization                     │
│  • Cannot access other organizations                    │
└─────────────────────────────────────────────────────────┘
                          │
                          │ manages
                          ▼
┌─────────────────────────────────────────────────────────┐
│                   PROFESSIONAL                          │
│  • Patient care focus                                   │
│  • Views patients in organization                       │
│  • Manages assigned patients                            │
│  • Logs health data & notes                            │
│  • Limited admin capabilities                           │
└─────────────────────────────────────────────────────────┘
```

---

## 🎨 Module Priority Matrix

### Priority 1: MUST BUILD FIRST ⭐⭐⭐

1. **Admin Authentication** (1-2 days)
   - Login screen
   - Role-based access
   - Session management

2. **Admin Dashboard** (2-3 days)
   - System overview
   - Quick stats
   - Recent activity
   - Navigation hub

3. **Organizations Management** (3-4 days)
   - List organizations (Super Admin)
   - Create organization
   - Edit organization
   - View organization details
   - My organization (Hospital Admin)

4. **User Management** (3-4 days)
   - List users
   - Create users
   - Edit users
   - Disable/enable users
   - Role assignment

5. **Patient Management** (4-5 days)
   - List patients
   - Create patient (w/o APP)
   - Add patient (w/ APP)
   - Patient detail/about page
   - Edit patient
   - Merge patients

### Priority 2: CORE CLINICAL FEATURES ⭐⭐

6. **Health Data Management** (3 days)
   - View health data
   - Add glucose, BP, weight, etc.
   - Edit data
   - Export data

7. **Appointments** (2 days)
   - Calendar view
   - Create appointments
   - Edit appointments
   - Delete appointments

8. **Medications** (3 days)
   - Medications library (Super Admin)
   - Patient medications
   - Patient allergies
   - Patient diagnoses

9. **Practice Groups** (4 days)
   - List groups
   - Create group
   - Group details
   - Add patients/professionals
   - Group reports

10. **Patient Remarks** (2 days)
    - View remarks
    - Add clinical notes
    - Edit notes

### Priority 3: MONITORING & ANALYSIS ⭐

11. **Logbook & Trends** (3 days)
    - Log view
    - Chart view
    - Table view
    - Pattern analysis

12. **Events Monitoring** (2 days)
    - Hyper/hypo events
    - Event criteria
    - Event alerts

13. **Audit Logs** (2-3 days)
    - Login logs
    - Activity logs
    - Device logs
    - Patient app data

14. **Roles & Permissions** (3 days)
    - Permissions management
    - Roles management
    - Permission assignment

---

## 🔑 Key Screens by Role

### Super Admin Screens (Complete Admin Panel)

| Module | Screens | Count |
|--------|---------|-------|
| Organizations | List, Create, Edit, Detail | 4 |
| Users | List, Create, Edit, Detail | 4 |
| Patients | List, Create, Add, About, Edit, Merge | 6 |
| Practice Groups | List, Detail, Create, Edit | 4 |
| Roles & Permissions | Permissions (List, Create, Edit), Roles (List, Create, Edit) | 6 |
| Audit Logs | Login, Activity, Device, App Data | 4 |
| Events | Hyper Glucose, Hypo Glucose, Hyper BP, Hypo BP | 4 |
| Appointments | Calendar/List | 1 |
| Medications | Library, Import | 2 |
| Patient Modules | Medications, Remarks, Health Data, Logbook | 4 |
| System | Dashboard, Settings | 2 |
| **Total** | | **41 screens** |

### Hospital Admin Screens (Reduced Access)

| Module | Screens | Count |
|--------|---------|-------|
| My Organization | Detail, Edit | 2 |
| Users | List, Create, Edit, Detail (own org) | 4 |
| Patients | List, Create, Add, About, Edit, Merge (own org) | 6 |
| Practice Groups | List, Detail, Create, Edit (own org) | 4 |
| Roles | List, Edit (own org) | 2 |
| Events | Hyper/Hypo (own org) | 4 |
| Appointments | Calendar/List | 1 |
| Medications | Library (view only) | 1 |
| Patient Modules | Medications, Remarks, Health Data, Logbook | 4 |
| **Total** | | **28 screens** |

### Professional Screens (Patient Care Focus)

| Module | Screens | Count |
|--------|---------|-------|
| Patients | List, About, Edit (own org) | 3 |
| Practice Groups | List, Detail (assigned only) | 2 |
| Events | Hyper/Hypo (own org) | 4 |
| Appointments | Calendar/List | 1 |
| Patient Modules | Medications, Remarks, Health Data, Logbook | 4 |
| **Total** | | **14 screens** |

---

## 🏗️ Recommended Build Order

### Week 1: Foundation
```
Day 1-2:  Authentication & Navigation
Day 3-4:  Admin Dashboard
Day 5-7:  Organizations Management (Super Admin)
```

### Week 2: Core User & Patient Management
```
Day 1-2:  User Management (all roles)
Day 3-5:  Patient Management (List, Create, Edit)
Day 6-7:  Patient About/Detail Page
```

### Week 3: Clinical Features
```
Day 1-2:  Health Data Management
Day 3-4:  Appointments
Day 5-7:  Medications & Patient Medications
```

### Week 4: Groups & Monitoring
```
Day 1-3:  Practice Groups
Day 4-5:  Patient Remarks
Day 6-7:  Events Monitoring
```

### Week 5: Analysis & Admin Features
```
Day 1-2:  Logbook & Trends
Day 3-4:  Audit Logs
Day 5-7:  Roles & Permissions
```

---

## 🎯 Per-Module Feature Matrix

### Patient Management Module

| Feature | Super Admin | Hospital Admin | Professional |
|---------|-------------|----------------|--------------|
| View patients (all orgs) | ✅ | 🔒 | 🔒 |
| View patients (own org) | ✅ | ✅ | ✅ |
| Create patient (any org) | ✅ | 🔒 | 🔒 |
| Create patient (own org) | ✅ | ✅ | ✅ |
| Edit patient (any org) | ✅ | 🔒 | 🔒 |
| Edit patient (own org) | ✅ | ✅ | ✅ |
| Merge patients | ✅ | ✅ (own org) | ✅ (own org) |
| Filter: With/Without Org | ✅ | 🔒 | 🔒 |

### User Management Module

| Feature | Super Admin | Hospital Admin | Professional |
|---------|-------------|----------------|--------------|
| View users (all orgs) | ✅ | 🔒 | 🔒 |
| View users (own org) | ✅ | ✅ | 👁️ (read-only) |
| Create user (any org) | ✅ | 🔒 | 🔒 |
| Create user (own org) | ✅ | ✅ | 🔒 |
| Edit user (any org) | ✅ | 🔒 | 🔒 |
| Edit user (own org) | ✅ | ✅ | 🔒 |
| Disable user (any org) | ✅ | 🔒 | 🔒 |
| Disable user (own org) | ✅ | ✅ | 🔒 |

### Organization Management Module

| Feature | Super Admin | Hospital Admin | Professional |
|---------|-------------|----------------|--------------|
| View all organizations | ✅ | 🔒 | 🔒 |
| View own organization | ✅ | ✅ | 👁️ (read-only) |
| Create organization | ✅ | 🔒 | 🔒 |
| Edit any organization | ✅ | 🔒 | 🔒 |
| Edit own organization | ✅ | ✅ | 🔒 |

### Practice Groups Module

| Feature | Super Admin | Hospital Admin | Professional |
|---------|-------------|----------------|--------------|
| View groups (all orgs) | ✅ | 🔒 | 🔒 |
| View groups (own org) | ✅ | ✅ | ⚠️ (assigned only) |
| Create group | ✅ | ✅ | ✅ |
| Edit group | ✅ | ✅ (own org) | ✅ (if manager) |
| Add patients | ✅ | ✅ | ✅ |
| Add professionals | ✅ | ✅ | ✅ |
| Generate reports | ✅ | ✅ | ✅ |

### Roles & Permissions Module

| Feature | Super Admin | Hospital Admin | Professional |
|---------|-------------|----------------|--------------|
| View all permissions | ✅ | 🔒 | 🔒 |
| Create permission | ✅ | 🔒 | 🔒 |
| Edit permission | ✅ | 🔒 | 🔒 |
| View roles (all orgs) | ✅ | 🔒 | 🔒 |
| View roles (own org) | ✅ | ✅ | 🔒 |
| Create role | ✅ | 🔒 | 🔒 |
| Edit role (allowed perms) | ✅ | 🔒 | 🔒 |
| Edit role (default perms) | ✅ | ✅ (own org) | 🔒 |

### Audit Logs Module

| Feature | Super Admin | Hospital Admin | Professional |
|---------|-------------|----------------|--------------|
| View login logs (all) | ✅ | 🔒 | 🔒 |
| View login logs (own org) | ✅ | 👁️ | 🔒 |
| View activity logs (all) | ✅ | 🔒 | 🔒 |
| View activity logs (own org) | ✅ | 👁️ | 🔒 |
| View device logs (all) | ✅ | 🔒 | 🔒 |
| View device logs (own org) | ✅ | 👁️ | 🔒 |
| Export logs | ✅ | ⚠️ (own org) | 🔒 |

### Clinical Modules (Equal Access)

| Module | Super Admin | Hospital Admin | Professional |
|--------|-------------|----------------|--------------|
| Health Data | ✅ | ✅ | ✅ |
| Appointments | ✅ | ✅ | ✅ |
| Patient Medications | ✅ | ✅ | ✅ |
| Patient Remarks | ✅ | ✅ | ✅ |
| Logbook | ✅ | ✅ | ✅ |
| Events Monitoring | ✅ | ✅ | ✅ |

*Note: All scoped to organization for Hospital Admin & Professional*

---

## 🔐 Critical Security Rules

### 1. Organization Boundary Enforcement

```
✅ DO:
- Filter ALL queries by organization_id
- Validate organization ownership on backend
- Return 403 for cross-org access

❌ DON'T:
- Trust frontend organization selection
- Allow cross-org access even with "view" permission
- Expose other organizations' data in API responses
```

### 2. Role-Based Access

```
✅ DO:
- Check role AND permission for every action
- Enforce role restrictions on backend
- Log all permission checks

❌ DON'T:
- Rely only on frontend permission checks
- Allow role escalation
- Skip permission validation
```

### 3. Form Tampering Protection

```
✅ DO:
- Ignore organization_id from form if not Super Admin
- Auto-set organization_id to user's org
- Validate ALL inputs on backend

❌ DON'T:
- Trust form data as-is
- Allow organization_id changes via form
- Skip server-side validation
```

### 4. Audit Everything

```
✅ LOG:
- All create/update/delete operations
- Login attempts (success/failure)
- Permission changes
- Data exports
- Cross-org access attempts

❌ DON'T:
- Log sensitive data (passwords)
- Skip error logging
- Allow log tampering
```

---

## 📋 Development Checklist by Module

### ✅ Organizations Module
- [ ] Organizations list screen (Super Admin)
- [ ] Create organization screen
- [ ] Organization detail screen
- [ ] Edit organization screen
- [ ] My organization screen (Hospital Admin)
- [ ] Organization stats widgets
- [ ] Backend: RLS policies
- [ ] Backend: Validation

### ✅ Users Module
- [ ] Users list screen (with org filter)
- [ ] Create user screen
- [ ] User detail screen
- [ ] Edit user screen
- [ ] Role selector widget
- [ ] Permission checkboxes widget
- [ ] Backend: User CRUD
- [ ] Backend: Role assignment
- [ ] Backend: Email notifications

### ✅ Patients Module
- [ ] Patients list screen
- [ ] Advanced filters
- [ ] Create patient (w/o APP) screen
- [ ] Add patient (w/ APP) screen
- [ ] Patient about/detail screen
- [ ] Quick stats widgets
- [ ] Edit patient screen
- [ ] Merge patients screen
- [ ] Backend: Patient CRUD
- [ ] Backend: Duplicate detection
- [ ] Backend: Merge logic

### ✅ Practice Groups Module
- [ ] Groups list screen
- [ ] Group card widget
- [ ] Group detail screen
- [ ] Patients table with filters
- [ ] Professionals table
- [ ] Create group screen
- [ ] Edit group screen
- [ ] Add patients modal
- [ ] Add professionals modal
- [ ] Generate report screen
- [ ] Backend: Group CRUD
- [ ] Backend: Membership management
- [ ] Backend: Report generation

### ✅ Health Data Module
- [ ] Health data list screen
- [ ] Data type tabs
- [ ] Filters & search
- [ ] Add health data screen
- [ ] Data type selector
- [ ] Type-specific forms (glucose, BP, etc.)
- [ ] Edit health data screen
- [ ] Export data modal
- [ ] Backend: Health data CRUD
- [ ] Backend: Validation
- [ ] Backend: Unit conversions

### ✅ Appointments Module
- [ ] Appointments screen
- [ ] Calendar view widget
- [ ] List view widget
- [ ] Create appointment modal
- [ ] Edit appointment modal
- [ ] Conflict detection
- [ ] Backend: Appointment CRUD
- [ ] Backend: Email/SMS notifications

### ✅ Medications Module
- [ ] Medications library screen (Super Admin)
- [ ] Add medication modal
- [ ] Edit medication modal
- [ ] Import medications screen
- [ ] Patient medications screen
- [ ] Allergies section
- [ ] Diagnoses cards
- [ ] Medications list per diagnosis
- [ ] Add allergy modal
- [ ] Add diagnosis modal
- [ ] Add patient medication modal
- [ ] Backend: Medications CRUD
- [ ] Backend: Import logic

### ✅ Remarks Module
- [ ] Patient remarks screen
- [ ] Remark cards
- [ ] Create remark screen
- [ ] Rich text editor
- [ ] Edit remark screen
- [ ] Backend: Remarks CRUD
- [ ] Backend: Visibility rules

### ✅ Logbook Module
- [ ] Logbook screen
- [ ] Log view widget
- [ ] Chart view widget (line chart)
- [ ] Table view widget (grid)
- [ ] Time period selector
- [ ] Statistics panel
- [ ] Backend: Aggregations
- [ ] Backend: Chart data

### ✅ Events Module
- [ ] Hyper events (glucose) screen
- [ ] Hypo events (glucose) screen
- [ ] Hyper events (BP) screen
- [ ] Hypo events (BP) screen
- [ ] Event criteria form
- [ ] Event results table
- [ ] Backend: Event detection queries

### ✅ Audit Logs Module
- [ ] Login logs screen
- [ ] Activity logs screen
- [ ] Device logs screen
- [ ] Patient app data screen
- [ ] Log detail modals
- [ ] Filters & search
- [ ] Backend: Logging system
- [ ] Backend: Log queries

### ✅ Roles & Permissions Module
- [ ] Permissions list screen
- [ ] Create permission screen
- [ ] Edit permission screen
- [ ] Roles list screen
- [ ] Create role screen
- [ ] Edit role screen
- [ ] Permission checkboxes widget
- [ ] Permission categories widget
- [ ] Backend: Permissions CRUD
- [ ] Backend: Roles CRUD
- [ ] Backend: Permission enforcement

---

## 🎨 UI Component Library Needed

### Shared Admin Widgets

1. **Navigation**
   - AdminAppBar
   - AdminDrawer (with role-based menu)
   - BreadcrumbsBar

2. **Data Display**
   - AdminDataTable (with sorting, filtering, pagination)
   - StatsCard
   - ChartWidget
   - StatusBadge
   - EmptyState

3. **Inputs**
   - AdminTextField
   - AdminDropdown
   - AdminDatePicker
   - AdminTimePicker
   - AdminMultiSelect
   - AdminCheckboxGroup
   - AdminRadioGroup

4. **Actions**
   - AdminButton
   - AdminIconButton
   - ConfirmDialog
   - AlertDialog

5. **Filters**
   - FilterBar
   - SearchBar
   - DateRangeFilter
   - DropdownFilter

6. **Layout**
   - AdminLayout (with sidebar)
   - ContentCard
   - PageHeader
   - SectionHeader

---

## 🗂️ Database Schema Quick Reference

### Core Tables

1. **organizations**
   - id, code, name, login_url, settings, is_active

2. **users**
   - id, organization_id, email, username, role, permissions

3. **patients**
   - id, organization_id, patient_number, name, dob, diabetes_type

4. **practice_groups**
   - id, organization_id, title, dangerous_high, dangerous_low

5. **practice_group_members**
   - id, group_id, user_id (for professionals), patient_id

6. **health_readings**
   - id, patient_id, type, glucose_value, systolic, diastolic, etc.

7. **roles**
   - id, organization_id, name, allowed_permissions, default_permissions

8. **permissions**
   - id, name, code, category, description

9. **audit_logs**
   - id, user_id, action, resource_type, resource_id, changes

10. **appointments**
    - id, patient_id, professional_id, date, time, duration, type

---

## 🚀 Quick Start Guide

### Step 1: Set Up Environment
```bash
# Ensure Flutter & Supabase are configured
flutter doctor
```

### Step 2: Create Admin Folder Structure
```bash
mkdir -p lib/features/admin/{auth,dashboard,organizations,users,patients}
mkdir -p lib/shared/admin/widgets
```

### Step 3: Build Authentication First
1. Create admin_login_screen.dart
2. Implement role-based auth
3. Set up admin navigation

### Step 4: Build Dashboard
1. Create admin_dashboard_screen.dart
2. Add stats widgets
3. Add recent activity

### Step 5: Build First Core Module (Organizations)
1. List screen
2. Create screen
3. Edit screen
4. Connect to Supabase

### Step 6: Repeat for Each Module
- Follow priority order
- Build UI first
- Connect to backend
- Test thoroughly

---

## 📞 Support & Questions

### Common Questions

**Q: Can Hospital Admin see other organizations?**
A: No. Hospital Admin is strictly scoped to their own organization.

**Q: Can Professional create users?**
A: No. Only Super Admin and Hospital Admin can create users.

**Q: Who can access audit logs?**
A: Super Admin has full access. Hospital Admin can view logs for their organization only (read-only).

**Q: Can patients be transferred between organizations?**
A: Only Super Admin can change a patient's organization.

**Q: What happens if form is tampered?**
A: Backend validates and enforces organization boundaries. Tampering attempts are logged.

---

## 🎯 Success Criteria

### Phase 1 Complete When:
- ✅ Super Admin can create and manage organizations
- ✅ All roles can log in with proper access
- ✅ Dashboard shows system stats

### Phase 2 Complete When:
- ✅ Users can be created and managed
- ✅ Patients can be created and managed
- ✅ Patient detail page shows all info

### Phase 3 Complete When:
- ✅ Health data can be logged and viewed
- ✅ Appointments can be scheduled
- ✅ Medications can be prescribed

### Phase 4 Complete When:
- ✅ Practice groups work fully
- ✅ Events monitoring detects issues
- ✅ Reports can be generated

### Final Completion When:
- ✅ All 13 modules functional
- ✅ All 3 roles work correctly
- ✅ Security enforced at all levels
- ✅ Audit logging captures everything
- ✅ UI is polished and responsive

---

*Quick reference guide for GlucoGuide Admin Platform development*
*Refer to ADMIN_PLATFORM_REQUIREMENTS.md for detailed specifications*
