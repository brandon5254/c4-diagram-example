workspace "MindMate – C4 Model" "Interactive C4 diagrams for MindMate" {

  model {

    // === Personas ===
    patient = person "Patient/User" "Enters symptoms and reviews recommendations." {
      tags "person"
    }
    clinician = person "Clinician" "Reviews results, chats with patient, documents care." {
      tags "person"
    }

    // === External systems ===
    ehr = softwareSystem "Hospital EHR" "Official clinical record system." {
      tags "external"

      ehr_fhir = container "EHR FHIR Endpoint" "FHIR R4 API exposed by the hospital." "FHIR R4" {
        tags "external"
      }
    }

    // === MindMate system ===
    mindmate = softwareSystem "MindMate" "Symptom monitoring and clinical support in schizophrenia." {

      app = container "Mobile/Web App" "Symptoms form, results screen, chat." "Web/Mobile" {
        tags "frontend"
      }

      portal = container "Clinician Portal" "Results dashboard, history, chat." "Web" {
        tags "frontend"
      }

      apigw = container "API Gateway / Auth" "OAuth2/JWT, routing, rate-limit, TLS termination."

      biz = container "Business Logic" "Validation, feature building, recommendation rules."

      ml = container "ML Inference Engine" "Stacking with selective cost; predicts subtype + scores." {
        fe = component "Feature Builder" "From one-hot symptoms + cluster features."
        pred = component "Predictor" "Ensemble (RF + HGB/XGB) -> subtype + probabilities."
      }

      interop = container "Interoperability Service" "HL7® FHIR® API; resource mapping and posting."

      db = container "MindMate DB" "Tests, users, meds, chat threads." "Relational DB" {
        tags "database"
      }

      audit = container "Audit & Monitoring" "Logs, metrics, traces; model versioning."
    }

    // === People ↔ Systems ===
    patient -> app "Captures symptoms; views recommendations"
    clinician -> portal "Reviews results & chats"
    clinician -> ehr "Consults official record (if applicable)"

    // === App/Portal ↔ Backend ===
    app -> apigw "HTTPS/JSON"
    portal -> apigw "HTTPS/JSON"
    apigw -> biz "Routes + authenticates"
    biz -> ml "Build features -> infer subtype"
    ml -> biz "Subtype + scores + recommendation"
    biz -> db "Persist test + result"
    portal -> db "Reads history/metadata"

    // === Interoperability (HL7/FHIR) ===
    biz -> interop "Create FHIR resources\n(Observation, Condition, ServiceRequest)"
    interop -> ehr_fhir "POST/PUT FHIR over TLS"
    ehr_fhir -> interop "ACK + resource IDs"
    ehr_fhir -> portal "Clinician queries results (FHIR)"

    // === Cross-cutting ===
    apigw -> audit "Access logs"
    biz -> audit "Business events, metrics"
    ml -> audit "Model version, latency, confidences"
    interop -> audit "FHIR transactions"

    // === Optional reverse flow ===
    portal -> app "Feedback / recommendations (optional)"
    portal -> patient "Feedback / recommendations (optional)"
  }

  views {

    // ---- System Context (C4-1) ----
    systemContext mindmate mindmate_system_context {
      title "MindMate System Context"
      include *
      autolayout lr
    }

    // ---- Containers (C4-2) ----
    container mindmate mindmate_container_view {
      title "MindMate Container View"
      include *
      autolayout lr
    }

    // ---- Components of ML Engine (C4-3) ----
    component ml ml_component_view {
      title "ML Engine Component View"
      include *
      autolayout
    }

    // ---- Dynamic view: Symptom test flow ----
    dynamic mindmate symptom_test_flow {
      title "Symptom Test Flow"
      patient -> app "Enter symptoms"
      app -> apigw "Submit JSON (secured)"
      apigw -> biz "Validate + normalize"
      biz -> ml "Build features & predict"
      ml -> biz "Subtype + scores + rec"
      biz -> db "Store test + result"
      biz -> interop "Build FHIR Observation/Condition/ServiceRequest"
      interop -> ehr_fhir "Publish to EHR (FHIR)"
      ehr_fhir -> portal "Clinician queries results"
      portal -> patient "Optional feedback / advice"
      autolayout
    }

    styles {
      element "Software System" {
        background #0f6ab3
        color #ffffff
      }
      element "person" {
        shape Person
        background #08427b
        color #ffffff
      }
      element "frontend" {
        shape WebBrowser
        background #1168bd
        color #ffffff
      }
      element "database" {
        shape Cylinder
      }
      element "external" {
        background #eeeeee
        border dashed
        color #000000
      }
    }
  }
}
