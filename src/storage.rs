use crate::task::Task;
use anyhow::{Context, Result};
use dirs::config_dir;
use serde_json::to_writer_pretty;
use std::fs::{File, create_dir_all};
use std::path::PathBuf;

pub fn tasks_file() -> Result<PathBuf> {
    let mut dir = config_dir().unwrap_or_else(|| dirs::home_dir().expect("home dir not found"));
    dir.push("tdo");
    create_dir_all(&dir)?;
    dir.push("tasks.json");
    Ok(dir)
}

pub fn load_tasks() -> Result<Vec<Task>> {
    let path = tasks_file()?;
    if !path.exists() {
        return Ok(vec![]);
    }
    let file = File::open(&path).context("opening tasks file")?;
    let tasks = serde_json::from_reader(file).context("parsing tasks json")?;
    Ok(tasks)
}

pub fn save_tasks(tasks: &Vec<Task>) -> Result<()> {
    let path = tasks_file()?;
    let file = File::create(&path).context("creating tasks file")?;
    to_writer_pretty(file, tasks)?;
    Ok(())
}
