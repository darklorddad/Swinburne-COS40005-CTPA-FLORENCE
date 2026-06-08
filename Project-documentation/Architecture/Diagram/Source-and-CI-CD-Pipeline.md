graph TD
    subgraph GlobalPipeline ["Source and CI/CD Pipeline"]
        
        %% GITHUB SECTION
        subgraph GitHub ["GitHub"]
            subgraph Repo ["Repository (Source Control)"]
                Main["Branch: main<br/>(development)"]
                Prod["Branch: production"]
                Main -- "Pull Request<br/>(Review and Merge)" --> Prod
            end

            subgraph Actions ["Actions (Mobile CI/CD)"]
                Workflow["Workflow:<br/>Build and Distribute<br/>(main.yml)"]
                VersionCheck{"Version<br/>changed?"}
                Release["Shorebird Release<br/>(Build APK and Register)"]
                Patch["Shorebird Patch<br/>(Generate Patch)"]

                Workflow --> VersionCheck
                VersionCheck -- "Yes" --> Release
                VersionCheck -- "No" --> Patch
            end
            Prod -- "Auto-Trigger" --> Workflow
        end

        %% HOSTING & DISTRIBUTION SECTION
        subgraph Hosting ["Distribution and Hosting"]
            
            %% VERCEL
            subgraph Vercel ["Vercel Hosting (Serverless)"]
                subgraph Preview ["Preview Environment"]
                    DA_Dev["Project: ds<br/>Data Service<br/>(Development)"]
                    LLMS_Dev["Project: llmcs<br/>LLM Chatbot Service<br/>(Development)"]
                    WEB_Dev["Project: llmes<br/>LLM Engine Service<br/>(Development)"]
                end
                
                subgraph Production ["Production Environment"]
                    DA_Prod["Project: ds<br/>Data Service<br/>(Production)"]
                    LLMS_Prod["Project: llmcs<br/>LLM Chatbot Service<br/>(Production)"]
                    WEB_Prod_Engine["Project: llmes<br/>LLM Engine Service<br/>(Production)"]
                    WEB_Prod_Platform["Project: web<br/>Platform Service<br/>(Production)"]
                end
            end

            %% DISTRIBUTION
            subgraph Dist ["Mobile Distribution"]
                Firebase["Firebase App Distribution<br/>(Testers/QA)"]
                ShorebirdCloud["Shorebird Cloud<br/>(OTA Management)"]
            end

            %% END APP
            Florence["Florence"]
        end

        %% PIPELINE CONNECTIONS
        Main -- "Auto-Deploy" --> Preview
        Prod -- "Auto-Deploy" --> Production

        Release -- "Upload APK" --> Firebase
        Release -- "Register Release" --> ShorebirdCloud
        Patch -- "Publish Patch" --> ShorebirdCloud

        Firebase -- "Install (Mobile Application)" --> Florence
        ShorebirdCloud -- "Update (Mobile Application)" --> Florence
        WEB_Prod_Platform -- "Web Application" --> Florence

    end