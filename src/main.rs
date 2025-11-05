mod commands;
mod storage;
mod task;

use anyhow::Result;
use chrono::{NaiveDate, TimeZone, Utc}; 
use clap::ArgMatches;
use colored::*;
use commands::build_cli;
use std::io::{self, Write};
use storage::{load_tasks, save_tasks};
use task::Task;
use std::process;

fn main() -> Result<()> {
    let matches = build_cli().get_matches();
    match matches.subcommand() {
        Some(("add", sub)) => cmd_add(sub)?,
        Some(("list", sub)) => cmd_list(sub)?,
        Some(("done", sub)) => cmd_done(sub)?,
        Some(("delete", sub)) => cmd_delete(sub)?,
        Some(("reset", _)) => cmd_reset()?,
        None => {
            show_banner();
            println!("{}", "✨ Welcome to TDO - Your Rust-powered CLI To-Do App!".cyan());
            println!("Type {} to get started 🚀\n", "--help".yellow());
            process::exit(0);
        }
        _ => unreachable!(),
    }
    Ok(())
}

fn cmd_add(matches: &ArgMatches) -> Result<()> {
    let title = matches.get_one::<String>("title").unwrap().to_string();
    let due = matches
        .get_one::<String>("due")
        .map(|s| {
            NaiveDate::parse_from_str(s, "%Y-%m-%d")
                .map(|d| Utc.from_utc_datetime(&d.and_hms_opt(0, 0, 0).unwrap())) // ✅ FIXED
        })
        .transpose()?;
    let repeat = matches.get_one::<String>("repeat").cloned();

    let mut tasks = load_tasks()?;
    let t = Task::new(title, due, repeat);
    tasks.push(t);
    save_tasks(&tasks)?;
    println!("{}", "✅ Task added successfully!".green());
    Ok(())
}

fn cmd_list(_matches: &ArgMatches) -> Result<()> {
    let tasks = load_tasks()?;
    for (i, t) in tasks.iter().enumerate() {
        let status = if t.done { "[x]" } else { "[ ]" };
        let due = t
            .due
            .map(|d| d.format("%Y-%m-%d").to_string())
            .unwrap_or_default();
        println!(
            "{}. {} {} {} {}",
            i + 1,
            status,
            t.id,
            t.title,
            if due.is_empty() {
                "".into()
            } else {
                format!("(due: {})", due)
            }
        );
    }
    Ok(())
}

fn cmd_done(matches: &ArgMatches) -> Result<()> {
    use uuid::Uuid;
    let id = matches.get_one::<String>("id").unwrap();
    let uuid = Uuid::parse_str(id)?;
    let mut tasks = load_tasks()?;
    if let Some(t) = tasks.iter_mut().find(|t| t.id == uuid) {
        t.done = true;
        save_tasks(&tasks)?;
        println!("Marked done. ✅");
    } else {
        println!("Task not found.");
    }
    Ok(())
}

fn cmd_delete(matches: &ArgMatches) -> Result<()> {
    use uuid::Uuid;
    let id = matches.get_one::<String>("id").unwrap();
    let uuid = Uuid::parse_str(id)?;
    let mut tasks = load_tasks()?;
    tasks.retain(|t| t.id != uuid);
    save_tasks(&tasks)?;
    println!("{}", "❌ Task deleted!".red());
    Ok(())
}

fn cmd_reset() -> Result<()> {
    print!("⚠️  Are you sure you want to delete all tasks? (y/n): ");
    io::stdout().flush()?; // ensure prompt shows before waiting for input

    let mut input = String::new();
    io::stdin().read_line(&mut input)?;
    if input.trim().to_lowercase() != "y" {
        println!("❌ Reset cancelled.");
        return Ok(());
    }

    let mut tasks = load_tasks()?;
    tasks.clear();
    save_tasks(&tasks)?;
    println!("🧹 All tasks have been deleted successfully!");
    Ok(())
}

fn show_banner() {
    println!();
    println!("{}", "▄▄▄█████▓▓█████▄  ▒█████  ".cyan());
    println!("{}", "▓  ██▒ ▓▒▒██▀ ██▌▒██▒  ██▒".cyan());
    println!("{}", "▒ ▓██░ ▒░░██   █▌▒██░  ██▒".cyan());
    println!("{}", "░ ▓██▓ ░ ░▓█▄   ▌▒██   ██░".cyan());
    println!("{}", "  ▒██▒ ░ ░▒████▓ ░ ████▓▒░".cyan());
    println!("{}", "  ▒ ░░    ▒▒▓  ▒ ░ ▒░▒░▒░ ".cyan());
    println!("{}", "    ░     ░ ▒  ▒   ░ ▒ ▒░ ".cyan());
    println!("{}", "  ░       ░ ░  ░ ░ ░ ░ ▒  ".cyan());
    println!("{}", "            ░        ░ ░  ".cyan());
    println!("{}", "          ░               ".cyan());
    println!();
}
