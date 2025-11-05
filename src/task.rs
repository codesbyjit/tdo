use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Task {
    pub id: Uuid,
    pub title: String,
    pub done: bool,
    pub created_at: DateTime<Utc>,
    pub due: Option<DateTime<Utc>>,
    pub repeat: Option<String>, 
}

impl Task {
    pub fn new(title: String, due: Option<DateTime<Utc>>, repeat: Option<String>) -> Self {
        Self {
            id: Uuid::new_v4(),
            title,
            done: false,
            created_at: Utc::now(),
            due,
            repeat,
        }
    }
}
