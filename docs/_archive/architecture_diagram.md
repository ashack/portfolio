# System Architecture Diagram

## User Types & Access Flow

```mermaid
graph TB
    subgraph "Public Access"
        A[Public Homepage] --> B[Sign Up]
        A --> C[Sign In]
        A --> D[Pricing]
        A --> E[Features]
    end

    subgraph "Registration Paths"
        B --> F[Direct User Registration]
        F --> G{Choose Plan}
        G -->|Individual Plan| H[Individual User Created]
        G -->|Team Plan| I[Team Name Field Required]
        I --> J[Team + User Created<br/>owns_team: true]
        
        K[Invitation Link] --> L[Accept Invitation]
        L --> M[Invited User Registration<br/>Email Pre-filled]
        M --> N[Invited User Created<br/>Skip Confirmation]
        
        O[Super Admin] --> EG[Create Enterprise Group]
        EG --> EI[Send Admin Invitation]
        EI --> EA[Enterprise Admin Accepts]
        EA --> EU[Enterprise Admin Created]
        EU --> EM[Invite Members]
        EM --> EU2[Enterprise Users Created]
    end

    subgraph "User Types"
        O[Super Admin<br/>system_role: super_admin]
        P[Site Admin<br/>system_role: site_admin]
        Q[Direct User<br/>user_type: direct]
        R[Invited User<br/>user_type: invited]
        S[Enterprise User<br/>user_type: enterprise]
    end

    subgraph "Access Levels"
        O --> T[/admin/super/*]
        P --> U[/admin/site/*]
        Q --> V[/dashboard]
        Q --> W[/teams/team-slug/*<br/>if owns_team]
        R --> W
        S --> X[/enterprise/group-slug/*]
    end

    subgraph "Team Management"
        Y[Team Admin<br/>team_role: admin] --> Z[Send Invitations]
        Y --> AA[Manage Members]
        Y --> AB[Team Settings]
        Y --> AC[Team Billing]
        Y --> AR[Revoke Invitations<br/>Only if not accepted]
        
        AD[Team Member<br/>team_role: member] --> AE[Team Features]
        AD --> AF[Profile]
    end

    H --> V
    J --> W
    N --> W
    EU --> X
    Q -.->|Can create team| Y
    R -.->|Can be| Y
    R -.->|Can be| AD
    S -.->|Can be| Y
```

## Database Relationships

```mermaid
erDiagram
    User ||--o{ Team : "owns (direct users)"
    User }o--|| Team : "belongs to (invited users)"
    User ||--o{ Invitation : "sends"
    User }o--|| Plan : "has"
    User }o--o| EnterpriseGroup : "belongs to"
    
    Team ||--o{ User : "has members"
    Team ||--o{ Invitation : "has"
    Team }o--|| User : "administered by"
    
    Invitation }o--|| Team : "for (polymorphic)"
    Invitation }o--|| EnterpriseGroup : "for (polymorphic)"
    Invitation }o--|| User : "sent by"
    
    Plan ||--o{ User : "used by"
    
    EnterpriseGroup ||--o{ User : "has members"
    EnterpriseGroup }o--|| User : "administered by"
    EnterpriseGroup }o--|| Plan : "has"

    User {
        enum user_type "direct, invited, enterprise"
        enum system_role "user, site_admin, super_admin"
        enum status "active, inactive, locked"
        enum team_role "member, admin"
        boolean owns_team
        bigint team_id
        bigint plan_id
        bigint enterprise_group_id
    }
    
    Team {
        string name
        string slug
        enum status "active, suspended, cancelled"
        enum plan "starter, pro, enterprise"
        integer max_members
        bigint admin_id
    }
    
    Invitation {
        string invitable_type
        bigint invitable_id
        string invitation_type
        string email
        string token
        enum role "member, admin"
        datetime accepted_at
        datetime expires_at
        bigint team_id
        bigint invited_by_id
    }
    
    Plan {
        string name
        enum plan_segment "individual, team, enterprise"
        integer amount_cents
        boolean active
        boolean contact_sales
    }
    
    EnterpriseGroup {
        string name
        string slug
        enum status "active, suspended, cancelled"
        bigint admin_id
        bigint plan_id
    }
```

## Request Flow

```mermaid
sequenceDiagram
    participant U as User
    participant C as Controller
    participant P as Pundit
    participant M as Model
    participant D as Database

    U->>C: HTTP Request
    C->>C: authenticate_user!
    C->>C: check_user_status
    C->>P: authorize(resource)
    P->>P: Check Policy
    alt Authorized
        C->>M: Process Request
        M->>D: Database Query
        D-->>M: Data
        M-->>C: Response
        C-->>U: Render View
    else Not Authorized
        P-->>C: NotAuthorizedError
        C-->>U: Redirect/Error
    end
```

## Invitation Flow

```mermaid
sequenceDiagram
    participant TA as Team Admin
    participant S as System
    participant E as Email Service
    participant I as Invitee
    participant R as Registration

    TA->>S: Create Invitation
    S->>S: Validate Email (not existing user)
    S->>S: Generate Token
    S->>E: Send Invitation Email
    E->>I: Invitation Email
    I->>S: Click Invitation Link
    S->>S: Show Invitation Details
    I->>S: Accept Invitation
    S->>R: Redirect to Registration
    R->>R: Pre-fill Email (readonly)
    R->>R: Hide Plan Selection
    I->>R: Complete Registration
    alt Team Invitation
        R->>S: Create User (type: invited)
        R->>S: Associate with Team
        S->>I: Redirect to Team Dashboard
    else Enterprise Invitation
        R->>S: Create User (type: enterprise)
        R->>S: Associate with Enterprise Group
        alt Admin Invitation
            R->>S: Set as Enterprise Admin
        end
        S->>I: Redirect to Enterprise Dashboard
    end
    R->>S: Mark Invitation Accepted
    R->>S: Skip Email Confirmation
```

## State Transitions

```mermaid
stateDiagram-v2
    [*] --> Visitor
    
    Visitor --> DirectUser : Register (Individual Plan)
    Visitor --> TeamOwner : Register (Team Plan)
    Visitor --> InvitedUser : Accept Team Invitation
    Visitor --> EnterpriseUser : Accept Enterprise Invitation
    
    DirectUser --> TeamOwner : Create Team
    TeamOwner --> TeamOwner : Manage Team
    
    InvitedUser --> TeamMember : Default Role
    InvitedUser --> TeamAdmin : Admin Role
    
    TeamAdmin --> TeamAdmin : Manage Team
    TeamMember --> TeamAdmin : Role Change
    
    DirectUser --> Inactive : Status Change
    TeamOwner --> Inactive : Status Change
    InvitedUser --> Inactive : Status Change
    EnterpriseUser --> EnterpriseAdmin : Admin Role
    EnterpriseUser --> EnterpriseMember : Member Role
    EnterpriseUser --> Inactive : Status Change
    
    Inactive --> [*]
```

## Security Model

```mermaid
graph TB
    subgraph "Authentication Layer"
        A[Devise]
        A --> B[Email/Password]
        A --> C[Confirmable]
        A --> D[Lockable]
        A --> E[Trackable]
    end
    
    subgraph "Authorization Layer"
        F[Pundit Policies]
        F --> G[UserPolicy]
        F --> H[TeamPolicy]
        F --> I[InvitationPolicy]
        F --> J[PlanPolicy]
        F --> K[EnterpriseGroupPolicy]
    end
    
    subgraph "Security Checks"
        L[CSRF Protection]
        M[User Status Check]
        N[Team/Enterprise Membership]
        O[Role Validation]
        P[Invitation Expiry]
    end
    
    subgraph "Access Control"
        P{Request} --> A
        A --> F
        F --> L
        L --> M
        M --> N
        N --> O
        O --> P
        P --> Q{Allowed?}
        Q -->|Yes| R[Process Request]
        Q -->|No| S[Reject/Redirect]
    end
```

## Component Architecture

```mermaid
graph TB
    subgraph "Frontend"
        A[Tailwind CSS]
        B[Stimulus JS]
        C[Turbo]
        D[Phosphor Icons]
        E[ViewComponents]
        F[Tab Navigation]
    end
    
    subgraph "Controllers"
        E[ApplicationController]
        E --> F[Admin::BaseController]
        E --> G[Teams::BaseController]
        E --> H[Users::BaseController]
        E --> X[Enterprise::BaseController]
        F --> I[Admin::Super::*]
        F --> J[Admin::Site::*]
        G --> K[Teams::Admin::*]
        G --> L[Teams::*]
        X --> Y[Enterprise::*]
    end
    
    subgraph "Models"
        M[User]
        N[Team]
        O[Invitation]
        P[Plan]
        Q[EnterpriseGroup]
    end
    
    subgraph "Services"
        R[Teams::CreationService]
        S[Users::StatusManagementService]
        T[InvitationMailer]
    end
    
    subgraph "External Services"
        U[Stripe/Pay]
        V[Ahoy Analytics]
        W[Blazer Reports]
    end
```

## Deployment Architecture

```mermaid
graph TB
    subgraph "Production Stack"
        A[Nginx/Caddy] --> B[Puma App Server]
        B --> C[Rails Application]
        C --> D[PostgreSQL]
        C --> E[Redis]
        C --> F[Sidekiq]
        
        G[CDN] --> A
        H[S3/Storage] --> C
    end
    
    subgraph "Services"
        I[Stripe API]
        J[SMTP Server]
        K[Monitoring]
    end
    
    C --> I
    C --> J
    C --> K
```

---

Last Updated: June 2025