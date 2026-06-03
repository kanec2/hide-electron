%%{init: {'theme': 'base'}}%%

graph LR
    %% Правила: зависимости направлены ВНУТРЬ
    Presentation --> Application
    Application --> Domain
    Infrastructure --> Domain
    
    %% ЗАПРЕЩЁННЫЕ зависимости (красные пунктирные)
    Presentation -.-x Domain
    Presentation -.-x Infrastructure
    Application -.-x Presentation
    Application -.-x Infrastructure
    Infrastructure -.-x Presentation
    Infrastructure -.-x Application
    Domain -.-x Presentation
    Domain -.-x Application
    Domain -.-x Infrastructure
    
    %% Shared может использоваться всеми
    Shared -.- Presentation
    Shared -.- Application
    Shared -.- Domain
    Shared -.- Infrastructure
    
    classDef allowed stroke:#388e3c,stroke-width:2px
    classDef forbidden stroke:#c62828,stroke-width:2px,stroke-dasharray: 5 5
    
    Presentation --> Application,Application-->Domain,Infrastructure-->Domain
    Presentation-.-xDomain,Presentation-.-xInfrastructure,Application-.-xPresentation,Application-.-xInfrastructure,Infrastructure-.-xPresentation,Infrastructure-.-xApplication,Domain-.-xPresentation,Domain-.-xApplication,Domain-.-xInfrastructure