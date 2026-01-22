```mermaid
erDiagram
	%% Aturan Transisi (Rules)
    WORKFLOW_TRANSITION {
        INT id PK
        STRING scheme_id FK "PROCUREMENT"
        STRING current_state "DRAFT"
        STRING action_name "SUBMIT"
        STRING next_state "REVIEWED_BY_KOOR"
        
        %% Syarat (Guard)
        STRING required_role "MEMBER" 
        DECIMAL min_amount "0"
        DECIMAL max_amount "1000000"
    }
```