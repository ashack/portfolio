# System Overview Diagrams

## High-Level System Architecture

```mermaid
graph TB
    subgraph "Client Layer"
        Web["Web Browser<br/>(Desktop/Mobile)"]
        Mobile["Mobile App<br/>(Future)"]
        API["API Clients<br/>(Future)"]
    end
    
    subgraph "CDN & Security Layer"
        CF["CloudFlare<br/>(DDoS Protection)"]
        CDN["CDN<br/>(Static Assets)"]
    end
    
    subgraph "Application Layer"
        LB["Load Balancer<br/>(Nginx/Caddy)"]
        Rails1["Rails App 1<br/>(Puma)"]
        Rails2["Rails App 2<br/>(Puma)"]
        RailsN["Rails App N<br/>(Puma)"]
    end
    
    subgraph "Background Processing"
        Queue["Solid Queue<br/>(Job Processing)"]
        Worker1["Worker 1"]
        Worker2["Worker 2"]
        WorkerN["Worker N"]
    end
    
    subgraph "Data Layer"
        PG[(PostgreSQL<br/>Primary)]
        PGR[(PostgreSQL<br/>Read Replica)]
        Redis[(Redis<br/>Cache/Sessions)]
        S3["S3/Storage<br/>(Files)"]
    end
    
    subgraph "External Services"
        Stripe["Stripe API<br/>(Payments)"]
        Email["Email Service<br/>(SMTP/SendGrid)"]
        Monitor["Monitoring<br/>(Sentry/Skylight)"]
        Analytics["Analytics<br/>(Ahoy/Custom)"]
        Noticed["Notifications<br/>(Noticed Gem)"]
    end
    
    Web --> CF
    Mobile --> API
    API --> CF
    
    CF --> CDN
    CF --> LB
    
    LB --> Rails1
    LB --> Rails2
    LB --> RailsN
    
    Rails1 --> PG
    Rails2 --> PG
    RailsN --> PG
    
    Rails1 --> PGR
    Rails2 --> PGR
    
    Rails1 --> Redis
    Rails2 --> Redis
    RailsN --> Redis
    
    Rails1 --> Queue
    Rails2 --> Queue
    
    Queue --> Worker1
    Queue --> Worker2
    Queue --> WorkerN
    
    Worker1 --> PG
    Worker2 --> PG
    
    Rails1 --> Stripe
    Rails1 --> Email
    Rails1 --> S3
    
    Rails1 --> Monitor
    Rails2 --> Monitor
    
    Worker1 --> Email
    Worker2 --> Stripe
    
    classDef client fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef security fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef app fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef data fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    classDef external fill:#fce4ec,stroke:#880e4f,stroke-width:2px
    classDef worker fill:#e8eaf6,stroke:#283593,stroke-width:2px
    
    class Web,Mobile,API client
    class CF,CDN security
    class LB,Rails1,Rails2,RailsN app
    class PG,PGR,Redis,S3 data
    class Stripe,Email,Monitor,Analytics external
    class Queue,Worker1,Worker2,WorkerN worker
```

## Request Flow Architecture

```mermaid
sequenceDiagram
    participant Client
    participant CDN
    participant LB as Load Balancer
    participant Rails
    participant Cache as Redis Cache
    participant DB as PostgreSQL
    participant Queue as Job Queue
    participant External as External Services
    
    Client->>CDN: Request
    
    alt Static Asset
        CDN-->>Client: Return Cached Asset
    else Dynamic Request
        CDN->>LB: Forward Request
        LB->>Rails: Route to App Server
        
        Rails->>Rails: Authenticate User
        Rails->>Rails: Authorize Action
        
        alt Cache Hit
            Rails->>Cache: Check Cache
            Cache-->>Rails: Return Cached Data
        else Cache Miss
            Rails->>DB: Query Database
            DB-->>Rails: Return Data
            Rails->>Cache: Store in Cache
        end
        
        alt Background Job Needed
            Rails->>Queue: Enqueue Job
            Queue-->>Rails: Job ID
            
            Note over Queue,External: Async Processing
            Queue->>External: Process Job
            External-->>Queue: Complete
        end
        
        Rails-->>Client: Response
    end
```

## Triple-Track User System Architecture

```mermaid
graph TB
    subgraph "User Registration"
        Public["Public Registration"]
        Invite["Invitation Link"]
        Enterprise["Enterprise Invite"]
    end
    
    subgraph "User Types"
        Direct["Direct Users<br/>(Personal Billing)"]
        Invited["Invited Users<br/>(Team Members)"]
        EntUser["Enterprise Users<br/>(Organization)"]
    end
    
    subgraph "Access Patterns"
        IndDash["Individual Dashboard<br/>(/dashboard)"]
        TeamDash["Team Dashboard<br/>(/teams/slug)"]
        EntDash["Enterprise Dashboard<br/>(/enterprise/slug)"]
    end
    
    subgraph "Billing"
        PersonalBill["Personal Stripe<br/>Subscription"]
        TeamBill["Team Stripe<br/>Subscription"]
        EntBill["Enterprise<br/>Custom Billing"]
    end
    
    Public --> Direct
    Invite --> Invited
    Enterprise --> EntUser
    
    Direct --> IndDash
    Direct --> PersonalBill
    Direct -.->|Can Create| TeamDash
    
    Invited --> TeamDash
    TeamDash --> TeamBill
    
    EntUser --> EntDash
    EntDash --> EntBill
    
    style Direct fill:#e3f2fd,stroke:#1976d2
    style Invited fill:#f3e5f5,stroke:#7b1fa2
    style EntUser fill:#e1bee7,stroke:#4a148c
    style PersonalBill fill:#c8e6c9,stroke:#2e7d32
    style TeamBill fill:#fff9c4,stroke:#f9a825
    style EntBill fill:#d1c4e9,stroke:#5e35b1
```

## Component Communication

```mermaid
graph LR
    subgraph "Rails Application"
        Controller["Controllers<br/>(Request Handling)"]
        Service["Service Objects<br/>(Business Logic)"]
        Model["Models<br/>(Data Layer)"]
        Policy["Policies<br/>(Authorization)"]
        Job["Background Jobs<br/>(Async Tasks)"]
        Mailer["Mailers<br/>(Email)"]
        Query["Query Objects<br/>(Complex Queries)"]
        ViewComp["ViewComponents<br/>(Reusable UI)"]
    end
    
    subgraph "Data Storage"
        DB[(Database)]
        Cache[(Cache)]
        Session[(Sessions)]
        Files[(File Storage)]
    end
    
    subgraph "External APIs"
        Payment[Payment API]
        Email[Email API]
        Analytics[Analytics API]
    end
    
    Controller --> Policy
    Controller --> Service
    Controller --> ViewComp
    Service --> Model
    Service --> Query
    Service --> Job
    Service --> Mailer
    
    Model --> DB
    Query --> DB
    Query --> Cache
    Model --> Cache
    Controller --> Session
    
    Job --> Model
    Job --> Mailer
    Job --> Payment
    
    Mailer --> Email
    Controller --> Analytics
    Model --> Files
    ViewComp --> Cache
    
    style Controller fill:#e3f2fd
    style Service fill:#f3e5f5
    style Model fill:#e8f5e9
    style Policy fill:#fff3e0
    style Job fill:#fce4ec
    style Mailer fill:#e0f2f1
```

## Deployment Architecture

```mermaid
graph TB
    subgraph "Development"
        Dev["Developer Machine<br/>SQLite + Redis"]
        DevTest["Test Suite<br/>Minitest"]
    end
    
    subgraph "CI/CD Pipeline"
        GH["GitHub<br/>Source Control"]
        GHA["GitHub Actions<br/>CI/CD"]
        Tests["Automated Tests<br/>+ Security Scans"]
        Build["Docker Build<br/>+ Asset Compilation"]
    end
    
    subgraph "Staging Environment"
        StageApp["Staging App<br/>(1 instance)"]
        StageDB[(Staging DB)]
        StageRedis[(Staging Cache)]
    end
    
    subgraph "Production Environment"
        ProdLB["Load Balancer"]
        ProdApp1["Prod App 1"]
        ProdApp2["Prod App 2"]
        ProdAppN["Prod App N"]
        ProdDB[(Production DB<br/>+ Replica)]
        ProdRedis[(Redis Cluster)]
        ProdQueue["Job Workers<br/>(Auto-scaling)"]
    end
    
    subgraph "Monitoring"
        Logs["Log Aggregation"]
        APM["APM Service"]
        Alerts["Alert Manager"]
        Metrics["Metrics Dashboard"]
    end
    
    Dev --> GH
    GH --> GHA
    GHA --> Tests
    Tests --> Build
    
    Build --> StageApp
    StageApp --> StageDB
    StageApp --> StageRedis
    
    Build --> ProdLB
    ProdLB --> ProdApp1
    ProdLB --> ProdApp2
    ProdLB --> ProdAppN
    
    ProdApp1 --> ProdDB
    ProdApp2 --> ProdDB
    ProdAppN --> ProdDB
    
    ProdApp1 --> ProdRedis
    ProdApp2 --> ProdRedis
    
    ProdApp1 --> ProdQueue
    
    ProdApp1 --> Logs
    ProdApp2 --> APM
    APM --> Alerts
    Logs --> Metrics
    
    classDef dev fill:#e3f2fd,stroke:#1976d2
    classDef ci fill:#f3e5f5,stroke:#7b1fa2
    classDef stage fill:#fff3e0,stroke:#f57c00
    classDef prod fill:#e8f5e9,stroke:#388e3c
    classDef monitor fill:#fce4ec,stroke:#c2185b
    
    class Dev,DevTest dev
    class GH,GHA,Tests,Build ci
    class StageApp,StageDB,StageRedis stage
    class ProdLB,ProdApp1,ProdApp2,ProdAppN,ProdDB,ProdRedis,ProdQueue prod
    class Logs,APM,Alerts,Metrics monitor
```

## Security Architecture

```mermaid
graph TB
    subgraph "Network Security"
        FW["Firewall Rules"]
        DDoS["DDoS Protection"]
        WAF["Web Application Firewall"]
        SSL["SSL/TLS Encryption"]
    end
    
    subgraph "Application Security"
        Auth["Authentication<br/>(Devise)"]
        AuthZ["Authorization<br/>(Pundit)"]
        RateLimit["Rate Limiting<br/>(Rack::Attack)"]
        CSRF["CSRF Protection"]
        XSS["XSS Prevention"]
        SQLi["SQL Injection Prevention"]
        Params["Parameter Sanitization"]
    end
    
    subgraph "Data Security"
        Encrypt["Encryption at Rest"]
        Transit["Encryption in Transit"]
        Backup["Encrypted Backups"]
        PII["PII Protection"]
    end
    
    subgraph "Access Control"
        MFA["MFA (Future)"]
        RBAC["Role-Based Access"]
        Audit["Audit Logging"]
        Session["Session Management"]
    end
    
    subgraph "Monitoring"
        IDS["Intrusion Detection"]
        LogMon["Log Monitoring"]
        Anomaly["Anomaly Detection"]
        Incident["Incident Response"]
    end
    
    FW --> DDoS
    DDoS --> WAF
    WAF --> SSL
    SSL --> Auth
    
    Auth --> AuthZ
    AuthZ --> RateLimit
    RateLimit --> CSRF
    CSRF --> XSS
    XSS --> SQLi
    SQLi --> Params
    
    Params --> Encrypt
    Encrypt --> Transit
    Transit --> Backup
    Backup --> PII
    
    Auth --> MFA
    MFA --> RBAC
    RBAC --> Audit
    Audit --> Session
    
    Audit --> IDS
    IDS --> LogMon
    LogMon --> Anomaly
    Anomaly --> Incident
    
    style FW fill:#ffebee,stroke:#c62828
    style Auth fill:#e3f2fd,stroke:#1976d2
    style Encrypt fill:#e8f5e9,stroke:#388e3c
    style MFA fill:#fff3e0,stroke:#f57c00
    style IDS fill:#f3e5f5,stroke:#7b1fa2
```

## Data Flow Architecture

```mermaid
graph TB
    subgraph "User Input"
        Form["Web Forms"]
        API["API Requests"]
        Upload["File Uploads"]
    end
    
    subgraph "Validation Layer"
        Client["Client-side Validation<br/>(JavaScript)"]
        Server["Server-side Validation<br/>(Rails)"]
        Schema["Schema Validation<br/>(Database)"]
    end
    
    subgraph "Processing Layer"
        Control["Controllers<br/>(Request Routing)"]
        Service["Services<br/>(Business Logic)"]
        Jobs["Background Jobs<br/>(Async Processing)"]
    end
    
    subgraph "Data Layer"
        Model["Models<br/>(ORM)"]
        Query["Query Objects<br/>(Complex Queries)"]
        Cache["Cache Layer<br/>(Redis)"]
    end
    
    subgraph "Storage"
        Primary[(Primary DB)]
        Replica[(Read Replica)]
        Search["Search Index<br/>(Future)"]
        Files["File Storage<br/>(S3)"]
    end
    
    subgraph "Output"
        JSON["JSON APIs"]
        HTML["HTML Views"]
        Email["Email Notifications"]
        Export["Data Exports"]
    end
    
    Form --> Client
    API --> Server
    Upload --> Server
    
    Client --> Server
    Server --> Schema
    
    Server --> Control
    Control --> Service
    Service --> Jobs
    
    Service --> Model
    Model --> Query
    Query --> Cache
    
    Model --> Primary
    Query --> Replica
    Service --> Search
    Upload --> Files
    
    Service --> JSON
    Control --> HTML
    Jobs --> Email
    Service --> Export
    
    classDef input fill:#e1f5fe,stroke:#01579b
    classDef validate fill:#f3e5f5,stroke:#4a148c
    classDef process fill:#fff3e0,stroke:#e65100
    classDef data fill:#e8f5e9,stroke:#1b5e20
    classDef storage fill:#e0f2f1,stroke:#00695c
    classDef output fill:#fce4ec,stroke:#880e4f
    
    class Form,API,Upload input
    class Client,Server,Schema validate
    class Control,Service,Jobs process
    class Model,Query,Cache data
    class Primary,Replica,Search,Files storage
    class JSON,HTML,Email,Export output
```

## Performance & Caching Architecture

```mermaid
graph TB
    subgraph "Request Flow"
        Request["Incoming Request"]
        RateLimit["Rack::Attack<br/>Rate Limiting"]
        Router["Rails Router"]
    end
    
    subgraph "Caching Layers"
        CDN["CDN Cache<br/>(Static Assets)"]
        Fragment["Fragment Cache<br/>(View Partials)"]
        Model["Model Cache<br/>(Cacheable Concern)"]
        Query["Query Cache<br/>(Query Objects)"]
        Redis["Redis Cache<br/>(Sessions/Jobs)"]
    end
    
    subgraph "Background Processing"
        TrackActivity["TrackUserActivityJob<br/>(5-min intervals)"]
        EmailJob["Email Notifications"]
        BillingJob["Billing Updates"]
        CleanupJob["Data Cleanup"]
    end
    
    subgraph "Optimizations"
        Eager["Eager Loading<br/>(includes/preload)"]
        Indexes["15+ DB Indexes"]
        PreCalc["Pre-calculated<br/>Statistics"]
        N1["N+1 Query<br/>Prevention"]
    end
    
    Request --> RateLimit
    RateLimit --> Router
    Router --> CDN
    Router --> Fragment
    
    Fragment --> Model
    Model --> Query
    Query --> Redis
    
    Router --> TrackActivity
    TrackActivity --> Redis
    
    Query --> Eager
    Eager --> Indexes
    Indexes --> PreCalc
    PreCalc --> N1
    
    style RateLimit fill:#ffcdd2,stroke:#d32f2f
    style Redis fill:#e3f2fd,stroke:#1976d2
    style Eager fill:#c8e6c9,stroke:#2e7d32
    style TrackActivity fill:#f3e5f5,stroke:#7b1fa2
```

## Enterprise Architecture

```mermaid
graph LR
    subgraph "Enterprise Management"
        SuperAdmin["Super Admin<br/>Creates Groups"]
        EntInvite["Enterprise<br/>Invitation"]
        EntAdmin["Enterprise Admin<br/>(Invited)"]
        EntMembers["Enterprise<br/>Members"]
    end
    
    subgraph "Enterprise Features"
        PurpleUI["Purple Theme<br/>UI"]
        CustomBilling["Custom Billing<br/>Plans"]
        BulkMgmt["Bulk User<br/>Management"]
        AuditLog["Audit<br/>Logging"]
    end
    
    subgraph "Enterprise Namespace"
        EntBase["Enterprise::BaseController"]
        EntDash["Enterprise::DashboardController"]
        EntMember["Enterprise::MembersController"]
        EntSettings["Enterprise::SettingsController"]
    end
    
    subgraph "Polymorphic System"
        Invitation["Invitations Table<br/>(Polymorphic)"]
        TeamInv["Team<br/>Invitations"]
        EntInv["Enterprise<br/>Invitations"]
    end
    
    SuperAdmin --> EntInvite
    EntInvite --> EntAdmin
    EntAdmin --> EntMembers
    
    EntAdmin --> PurpleUI
    EntAdmin --> CustomBilling
    EntAdmin --> BulkMgmt
    EntAdmin --> AuditLog
    
    EntBase --> EntDash
    EntBase --> EntMember
    EntBase --> EntSettings
    
    Invitation --> TeamInv
    Invitation --> EntInv
    
    style PurpleUI fill:#e1bee7,stroke:#4a148c
    style EntBase fill:#d1c4e9,stroke:#5e35b1
    style Invitation fill:#fff9c4,stroke:#f9a825
```

## Scaling Architecture

```mermaid
graph LR
    subgraph "Phase 1: Monolith (Current)"
        M1["Single Rails App<br/>0-10k users"]
        M1DB[(Single Database)]
        M1Cache[(Basic Cache)]
    end
    
    subgraph "Phase 2: Horizontal Scaling"
        M2LB["Load Balancer"]
        M2App1["App Server 1"]
        M2App2["App Server 2"]
        M2AppN["App Server N"]
        M2DB[(Primary + Replica)]
        M2Cache[(Distributed Cache)]
        M2Queue["Job Queue Cluster"]
    end
    
    subgraph "Phase 3: Service Extraction"
        M3API["API Gateway"]
        M3Auth["Auth Service"]
        M3Bill["Billing Service"]
        M3Core["Core App"]
        M3Analytics["Analytics Service"]
        M3DB[(Sharded DBs)]
        M3Event["Event Bus"]
    end
    
    subgraph "Phase 4: Global Scale"
        M4Edge["Edge Locations"]
        M4Region1["Region 1 Cluster"]
        M4Region2["Region 2 Cluster"]
        M4RegionN["Region N Cluster"]
        M4Global[(Global DB)]
        M4Stream["Event Stream"]
    end
    
    M1 --> M1DB
    M1 --> M1Cache
    
    M2LB --> M2App1
    M2LB --> M2App2
    M2LB --> M2AppN
    M2App1 --> M2DB
    M2App1 --> M2Cache
    M2App1 --> M2Queue
    
    M3API --> M3Auth
    M3API --> M3Bill
    M3API --> M3Core
    M3API --> M3Analytics
    M3Core --> M3DB
    M3Auth --> M3Event
    M3Bill --> M3Event
    
    M4Edge --> M4Region1
    M4Edge --> M4Region2
    M4Edge --> M4RegionN
    M4Region1 --> M4Global
    M4Region1 --> M4Stream
    
    style M1 fill:#e3f2fd
    style M2LB fill:#f3e5f5
    style M3API fill:#fff3e0
    style M4Edge fill:#e8f5e9
```

## Current Application State (January 2025)

```mermaid
pie title "Code Quality Metrics"
    "Clean Code" : 247
    "RuboCop Offenses" : 253
```

```mermaid
pie title "Test Coverage"
    "Untested Code" : 98.67
    "Tested Code" : 1.33
```

```mermaid
graph LR
    subgraph "Priority Areas"
        Test["🔴 Test Coverage<br/>1.33% → 90%"]
        Quality["🟡 Code Quality<br/>253 offenses"]
        Security["🟡 Security<br/>1 warning"]
        Perf["✅ Performance<br/>< 100ms"]
    end
    
    subgraph "Technical Debt"
        Tests["498 tests<br/>42 errors<br/>34 skips"]
        Coverage["Line: 1.33%<br/>Branch: 0%"]
        Rubocop["253 offenses<br/>246 autocorrectable"]
        Brakeman["1 minor<br/>warning"]
    end
    
    Test --> Tests
    Test --> Coverage
    Quality --> Rubocop
    Security --> Brakeman
    
    style Test fill:#ffcdd2,stroke:#d32f2f
    style Quality fill:#fff9c4,stroke:#f9a825
    style Security fill:#fff9c4,stroke:#f9a825
    style Perf fill:#c8e6c9,stroke:#2e7d32
```

---

**Last Updated**: January 2025
**Related**: [User Flow Diagrams](user-flows.md) | [Database ERD](database-erd.md) | [Architecture Overview](../README.md)