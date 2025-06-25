# User Flow Diagrams

## User Registration Flows

### Direct User Registration Flow

```mermaid
flowchart TD
    Start([User visits site]) --> Home[Homepage]
    Home --> SignUp[Click Sign Up]
    SignUp --> RegForm[Registration Form]
    
    RegForm --> EnterInfo[Enter Email, Name, Password]
    EnterInfo --> SelectPlan{Select Plan Type}
    
    SelectPlan -->|Individual Plan| IndividualFlow[Individual Account Setup]
    SelectPlan -->|Team Plan| TeamFlow[Team Account Setup]
    
    IndividualFlow --> CreateUser1[Create Direct User]
    CreateUser1 --> CreateStripe1[Create Stripe Customer]
    CreateStripe1 --> SendConfirm1[Send Confirmation Email]
    SendConfirm1 --> ShowDashboard1[Redirect to Dashboard]
    
    TeamFlow --> ShowTeamName[Show Team Name Field]
    ShowTeamName --> EnterTeamName[Enter Team Name]
    EnterTeamName --> CreateUser2[Create Direct User]
    CreateUser2 --> CreateTeam[Create Team Record]
    CreateTeam --> SetOwnership[Set owns_team = true]
    SetOwnership --> CreateStripe2[Create Team Stripe Customer]
    CreateStripe2 --> SendConfirm2[Send Confirmation Email]
    SendConfirm2 --> ShowTeamDash[Redirect to Team Dashboard]
    
    ShowDashboard1 --> ConfirmEmail1{Email Confirmed?}
    ShowTeamDash --> ConfirmEmail2{Email Confirmed?}
    
    ConfirmEmail1 -->|No| Limited1[Limited Access]
    ConfirmEmail1 -->|Yes| Full1[Full Access]
    
    ConfirmEmail2 -->|No| Limited2[Limited Access]
    ConfirmEmail2 -->|Yes| Full2[Full Team Access]
    
    style Start fill:#e8f5e9
    style Full1 fill:#c8e6c9
    style Full2 fill:#c8e6c9
    style Limited1 fill:#ffcdd2
    style Limited2 fill:#ffcdd2
```

### Team Invitation Flow

```mermaid
sequenceDiagram
    participant TA as Team Admin
    participant System
    participant Email as Email Service
    participant Invitee
    participant Reg as Registration
    
    TA->>System: Access Team Settings
    System->>TA: Show Invitation Form
    TA->>System: Enter Email Address
    
    System->>System: Validate Email Not Exists
    alt Email Already Exists
        System-->>TA: Error: User Already Exists
    else Email Available
        System->>System: Generate Secure Token
        System->>System: Create Invitation Record
        System->>System: Set Expiry (7 days)
        System->>Email: Send Invitation Email
        Email->>Invitee: Deliver Invitation
        
        Note over Invitee: Clicks Accept Link
        
        Invitee->>System: GET /invitations/:token
        System->>System: Validate Token
        
        alt Token Invalid/Expired
            System-->>Invitee: Error: Invalid/Expired
        else Token Valid
            System->>Invitee: Show Invitation Details
            Invitee->>System: Accept Invitation
            System->>Reg: Redirect to Registration
            
            Reg->>Invitee: Show Registration Form
            Note over Reg: Email Pre-filled & Locked
            Note over Reg: No Plan Selection
            
            Invitee->>Reg: Enter Name & Password
            Reg->>System: Create User Account
            
            System->>System: Set user_type = 'invited'
            System->>System: Set team_id from invitation
            System->>System: Set team_role from invitation
            System->>System: Skip email confirmation
            System->>System: Mark invitation accepted
            
            System->>Invitee: Redirect to Team Dashboard
        end
    end
```

### Enterprise User Flow

```mermaid
flowchart TD
    SA[Super Admin] --> CreateEnt[Create Enterprise Group]
    CreateEnt --> EnterDetails[Enter Organization Details]
    EnterDetails --> SelectPlan[Select Enterprise Plan]
    SelectPlan --> SetContact[Set Contact Info]
    SetContact --> CreateGroup[Create Enterprise Group Record]
    
    CreateGroup --> InviteAdmin{Invite Admin?}
    InviteAdmin -->|Yes| SendAdminInv[Send Admin Invitation]
    InviteAdmin -->|No| ManualSetup[Manual Setup Later]
    
    SendAdminInv --> AdminEmail[Admin Receives Email]
    AdminEmail --> AdminAccept[Admin Accepts Invitation]
    AdminAccept --> AdminReg[Admin Registration]
    AdminReg --> CreateAdmin[Create Enterprise Admin User]
    CreateAdmin --> AssignAdmin[Assign as Group Admin]
    AssignAdmin --> AdminDash[Access Enterprise Dashboard]
    
    AdminDash --> InviteMembers[Invite Team Members]
    InviteMembers --> MemberFlow[Member Invitation Flow]
    MemberFlow --> MemberReg[Member Registration]
    MemberReg --> CreateMember[Create Enterprise Member]
    CreateMember --> MemberAccess[Access Enterprise Portal]
    
    style SA fill:#ffebee
    style AdminDash fill:#e8f5e9
    style MemberAccess fill:#e3f2fd
```

## Authentication & Authorization Flows

### Login Flow with Security Checks

```mermaid
flowchart TD
    Start([User Login]) --> EnterCreds[Enter Email/Password]
    EnterCreds --> Submit[Submit Form]
    
    Submit --> ValidateEmail{Valid Email?}
    ValidateEmail -->|No| EmailError[Show Email Error]
    ValidateEmail -->|Yes| CheckUser{User Exists?}
    
    CheckUser -->|No| GenericError[Invalid Credentials]
    CheckUser -->|Yes| CheckLocked{Account Locked?}
    
    CheckLocked -->|Yes| ShowLocked[Account Locked Message]
    CheckLocked -->|No| ValidatePass{Valid Password?}
    
    ValidatePass -->|No| IncAttempts[Increment Failed Attempts]
    ValidatePass -->|Yes| CheckConfirmed{Email Confirmed?}
    
    IncAttempts --> CheckMax{5+ Attempts?}
    CheckMax -->|Yes| LockAccount[Lock Account]
    CheckMax -->|No| GenericError
    
    LockAccount --> SendUnlock[Send Unlock Email]
    SendUnlock --> ShowLocked
    
    CheckConfirmed -->|No| ResendOption[Show Resend Confirmation]
    CheckConfirmed -->|Yes| CheckStatus{User Active?}
    
    CheckStatus -->|No| InactiveError[Account Inactive]
    CheckStatus -->|Yes| CheckUserType{User Type?}
    
    CheckUserType -->|Direct| DirectRoute{Has Team?}
    CheckUserType -->|Invited| TeamRoute[Route to Team Dashboard]
    CheckUserType -->|Enterprise| EntRoute[Route to Enterprise Dashboard]
    
    DirectRoute -->|Yes| TeamDash[Team Dashboard]
    DirectRoute -->|No| UserDash[User Dashboard]
    
    style Start fill:#e8f5e9
    style UserDash fill:#c8e6c9
    style TeamDash fill:#c8e6c9
    style EntRoute fill:#c8e6c9
    style ShowLocked fill:#ffcdd2
    style InactiveError fill:#ffcdd2
    style GenericError fill:#ffcdd2
```

### Permission Check Flow

```mermaid
flowchart TD
    Request([HTTP Request]) --> Auth{Authenticated?}
    
    Auth -->|No| RedirectLogin[Redirect to Login]
    Auth -->|Yes| LoadResource[Load Resource]
    
    LoadResource --> CheckPolicy[Check Pundit Policy]
    CheckPolicy --> SystemRole{System Role?}
    
    SystemRole -->|Super Admin| AllowAll[Allow All Actions]
    SystemRole -->|Site Admin| CheckSiteAdmin{Site Admin Allowed?}
    SystemRole -->|User| CheckUserContext{Check Context}
    
    CheckSiteAdmin -->|Yes| AllowAction[Allow Action]
    CheckSiteAdmin -->|No| DenyAction[Deny Action]
    
    CheckUserContext --> UserType{User Type?}
    
    UserType -->|Direct| CheckDirect{Own Resource?}
    UserType -->|Invited| CheckTeam{Same Team?}
    UserType -->|Enterprise| CheckEnt{Same Enterprise?}
    
    CheckDirect -->|Yes| CheckDirectPerms[Check Permissions]
    CheckDirect -->|No| DenyAction
    
    CheckTeam -->|Yes| CheckTeamRole{Team Role?}
    CheckTeam -->|No| DenyAction
    
    CheckEnt -->|Yes| CheckEntRole{Enterprise Role?}
    CheckEnt -->|No| DenyAction
    
    CheckTeamRole -->|Admin| AllowTeamAdmin[Allow Admin Actions]
    CheckTeamRole -->|Member| AllowMember[Allow Member Actions]
    
    CheckEntRole -->|Admin| AllowEntAdmin[Allow Admin Actions]
    CheckEntRole -->|Member| AllowEntMember[Allow Member Actions]
    
    CheckDirectPerms --> AllowAction
    AllowTeamAdmin --> AllowAction
    AllowMember --> AllowAction
    AllowEntAdmin --> AllowAction
    AllowEntMember --> AllowAction
    AllowAll --> AllowAction
    
    AllowAction --> ExecuteAction[Execute Action]
    DenyAction --> Return403[403 Forbidden]
    
    style Request fill:#e8f5e9
    style AllowAction fill:#c8e6c9
    style ExecuteAction fill:#c8e6c9
    style DenyAction fill:#ffcdd2
    style Return403 fill:#ffcdd2
```

## Team Management Flows

### Team Member Management

```mermaid
stateDiagram-v2
    [*] --> TeamDashboard
    
    TeamDashboard --> MembersList : View Members
    
    MembersList --> InviteNew : Invite Member
    MembersList --> EditMember : Select Member
    
    InviteNew --> EnterEmail : Click Invite
    EnterEmail --> ValidateEmail : Submit
    
    ValidateEmail --> EmailExists : Email In Use
    ValidateEmail --> CreateInvitation : Email Available
    
    EmailExists --> ShowError
    ShowError --> EnterEmail
    
    CreateInvitation --> SendEmail
    SendEmail --> ShowPending
    ShowPending --> MembersList
    
    EditMember --> ViewDetails : View
    EditMember --> ChangeRole : Change Role
    EditMember --> RemoveMember : Remove
    
    ChangeRole --> ConfirmChange : Select New Role
    ConfirmChange --> UpdateRole : Confirm
    UpdateRole --> MembersList
    
    RemoveMember --> ConfirmRemove : Confirm Dialog
    ConfirmRemove --> DeleteUser : Confirm
    ConfirmRemove --> MembersList : Cancel
    DeleteUser --> MembersList
    
    note right of DeleteUser
        Completely removes user account
        Cannot be undone
    end note
    
    note right of ShowPending
        Invitation expires in 7 days
        Can be revoked if not accepted
    end note
```

### Billing Management Flow

```mermaid
flowchart TD
    Start([Team Admin Access]) --> Billing[Billing Dashboard]
    
    Billing --> ViewCurrent{Current Plan}
    ViewCurrent --> Starter[Starter Plan<br/>$49/mo - 5 members]
    ViewCurrent --> Pro[Pro Plan<br/>$99/mo - 15 members]
    ViewCurrent --> Enterprise[Enterprise Plan<br/>$199/mo - 100 members]
    
    Billing --> Actions{Billing Actions}
    
    Actions --> ChangePlan[Change Plan]
    Actions --> UpdateCard[Update Card]
    Actions --> CancelSub[Cancel Subscription]
    Actions --> ViewInvoices[View Invoices]
    
    ChangePlan --> SelectNew[Select New Plan]
    SelectNew --> PreviewChange[Preview Changes]
    PreviewChange --> ConfirmChange{Confirm?}
    ConfirmChange -->|Yes| ProcessChange[Process with Stripe]
    ConfirmChange -->|No| Billing
    
    ProcessChange --> UpdateDB[Update Database]
    UpdateDB --> SendConfirm[Send Confirmation]
    SendConfirm --> ShowSuccess[Show Success]
    
    UpdateCard --> CardForm[Card Details Form]
    CardForm --> ValidateCard[Validate with Stripe]
    ValidateCard --> SaveCard[Save Payment Method]
    SaveCard --> ShowSuccess
    
    CancelSub --> CancelWarn[Show Warnings]
    CancelWarn --> ConfirmCancel{Really Cancel?}
    ConfirmCancel -->|Yes| ProcessCancel[Cancel in Stripe]
    ConfirmCancel -->|No| Billing
    
    ProcessCancel --> ScheduleEnd[Schedule End Date]
    ScheduleEnd --> SendCancelEmail[Send Cancellation Email]
    SendCancelEmail --> ShowCancelled[Show Cancelled Status]
    
    style Start fill:#e8f5e9
    style ShowSuccess fill:#c8e6c9
    style ShowCancelled fill:#ffcdd2
```

## User Journey Maps

### Direct User Journey

```mermaid
journey
    title Direct User Journey
    
    section Discovery
      Visit Homepage: 5: User
      View Pricing: 4: User
      Compare Plans: 3: User
    
    section Registration
      Click Sign Up: 5: User
      Choose Individual Plan: 4: User
      Enter Details: 3: User
      Confirm Email: 2: User
    
    section Onboarding
      Access Dashboard: 5: User
      Complete Profile: 4: User
      Explore Features: 4: User
    
    section Usage
      Use Core Features: 5: User
      Check Analytics: 4: User
      Manage Billing: 3: User
    
    section Growth
      Upgrade Plan: 4: User
      Create Team: 5: User
      Invite Members: 4: User
```

### Team Member Journey

```mermaid
journey
    title Team Member Journey
    
    section Invitation
      Receive Email: 5: Invitee
      Click Accept: 5: Invitee
      View Team Info: 4: Invitee
    
    section Registration
      Create Account: 4: Invitee
      Set Password: 3: Invitee
      Complete Profile: 4: Invitee
    
    section Onboarding
      Access Team Dashboard: 5: Member
      Meet Team: 5: Member
      Learn Tools: 3: Member
    
    section Collaboration
      Use Team Features: 5: Member
      Share Resources: 4: Member
      Participate: 5: Member
    
    section Growth
      Become Admin: 3: Member
      Invite Others: 4: Admin
      Manage Team: 4: Admin
```

## Error & Recovery Flows

### Password Reset Flow

```mermaid
sequenceDiagram
    participant User
    participant System
    participant Email
    participant Reset as Reset Page
    
    User->>System: Click "Forgot Password"
    System->>User: Show Email Form
    User->>System: Submit Email
    
    System->>System: Validate Email Format
    alt Invalid Email
        System-->>User: Show Format Error
    else Valid Email
        System->>System: Check User Exists
        
        Note over System: Always show same message<br/>for security
        
        System->>User: "Check your email"
        
        alt User Exists
            System->>System: Generate Reset Token
            System->>System: Set Token Expiry (2 hours)
            System->>Email: Send Reset Email
            Email->>User: Deliver Reset Link
        else User Not Found
            Note over System: No email sent<br/>Security measure
        end
    end
    
    User->>Reset: Click Reset Link
    Reset->>System: Validate Token
    
    alt Token Invalid/Expired
        System-->>Reset: Show Error
        Reset-->>User: Link Invalid/Expired
    else Token Valid
        Reset->>User: Show Password Form
        User->>Reset: Enter New Password
        Reset->>System: Validate Password
        
        alt Password Invalid
            System-->>Reset: Show Requirements
        else Password Valid
            System->>System: Update Password
            System->>System: Clear Reset Token
            System->>System: Invalidate Sessions
            System->>Email: Send Confirmation
            System->>User: Redirect to Login
        end
    end
```

### Account Recovery Flow

```mermaid
flowchart TD
    Start([Account Issue]) --> Type{Issue Type?}
    
    Type -->|Locked Account| Locked[Account Locked]
    Type -->|Unconfirmed Email| Unconfirmed[Email Not Confirmed]
    Type -->|Deactivated| Deactivated[Account Deactivated]
    
    Locked --> CheckEmail[Check Email for Unlock]
    CheckEmail --> ClickUnlock[Click Unlock Link]
    ClickUnlock --> ValidateToken{Valid Token?}
    ValidateToken -->|Yes| UnlockAccount[Unlock Account]
    ValidateToken -->|No| RequestNew[Request New Unlock]
    UnlockAccount --> CanLogin[Can Login]
    
    Unconfirmed --> ResendConfirm[Request Confirmation]
    ResendConfirm --> CheckSpam[Check Spam Folder]
    CheckSpam --> ClickConfirm[Click Confirmation]
    ClickConfirm --> AccountActive[Account Activated]
    
    Deactivated --> ContactSupport[Contact Support]
    ContactSupport --> VerifyIdentity[Verify Identity]
    VerifyIdentity --> ReviewCase[Support Reviews]
    ReviewCase --> Decision{Reactivate?}
    Decision -->|Yes| Reactivate[Reactivate Account]
    Decision -->|No| StayDeactivated[Remain Deactivated]
    
    RequestNew --> SendNewUnlock[Send New Unlock Email]
    SendNewUnlock --> CheckEmail
    
    style Start fill:#e8f5e9
    style CanLogin fill:#c8e6c9
    style AccountActive fill:#c8e6c9
    style Reactivate fill:#c8e6c9
    style StayDeactivated fill:#ffcdd2
```

---

**Last Updated**: June 2025
**Previous**: [System Overview](system-overview.md)
**Next**: [Database ERD](database-erd.md)