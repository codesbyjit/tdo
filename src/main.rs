mod commands;
mod storage;
mod task;

use anyhow::Result;
use chrono::{NaiveDate, TimeZone, Utc};
use clap::ArgMatches;
use colored::*;
use commands::build_cli;
use std::io::{self, Write};
use std::process;
use storage::{load_tasks, save_tasks};
use task::Task;

fn main() -> Result<()> {
    let matches = build_cli().get_matches();
    match matches.subcommand() {
        Some(("add", sub)) => cmd_add(sub)?,
        Some(("list", sub)) => cmd_list(sub)?,
        Some(("done", _)) => cmd_done()?,
        Some(("delete", sub)) => cmd_delete(sub)?,
        Some(("reset", _)) => cmd_reset()?,
        None => {
            show_banner();
            println!("{}", "💫 Welcome to".bright_cyan());
            println!(
                "{}",
                "TDO — your glowing Rust-powered task buddy!".bright_purple()
            );
            println!(
                "👉 Type {} to explore commands 🚀\n",
                "--help".bright_yellow()
            );
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
                .map(|d| Utc.from_utc_datetime(&d.and_hms_opt(0, 0, 0).unwrap()))
        })
        .transpose()?;
    let repeat = matches.get_one::<String>("repeat").cloned();

    let mut tasks = load_tasks()?;
    let t = Task::new(title.clone(), due, repeat);
    tasks.push(t);
    save_tasks(&tasks)?;
    println!(
        "{} {}",
        "✨ Task added successfully:".bright_green(),
        title.bright_yellow()
    );
    Ok(())
}

fn cmd_list(_matches: &ArgMatches) -> Result<()> {
    let tasks = load_tasks()?;
    if tasks.is_empty() {
        println!("{}", "📭 No tasks found!".bright_yellow());
        return Ok(());
    }

    println!("{}", "\n🗒️  Your Current Tasks".bright_cyan().bold());
    println!("{}", "────────────────────────────────────────────────────".bright_black());
    for (i, t) in tasks.iter().enumerate() {
        let status = if t.done { "✔".bright_green() } else { "○".bright_magenta() };
        let due = t.due.map(|d| format!("(due: {})", d.format("%Y-%m-%d"))).unwrap_or_default();
        println!("{} {} {} {} {} ", (i + 1).to_string().bright_black(), status, t.title.bright_white(), due.bright_blue(), t.id,);
    }
    println!("{}", "─────────────────────────────-──────────────────────\n".bright_black());

    Ok(())
}

fn cmd_done() -> Result<()> {
    let tasks = load_tasks()?;
    if tasks.is_empty() {
        println!("{}", "📭 No tasks to mark as done!".bright_yellow());
        return Ok(());
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
    println!("{}", "🗑️  Task deleted!".bright_red());
    Ok(())
}

fn cmd_reset() -> Result<()> {
    print!(
        "{}",
        "⚠️  Are you sure you want to delete all tasks? (y/n): ".bright_yellow()
    );
    io::stdout().flush()?;

    let mut input = String::new();
    io::stdin().read_line(&mut input)?;
    if input.trim().to_lowercase() != "y" {
        println!("{}", "❌ Reset cancelled.".bright_red());
        return Ok(());
    }

    let mut tasks = load_tasks()?;
    tasks.clear();
    save_tasks(&tasks)?;
    println!("{}", "🧹 All tasks have been wiped clean!".bright_cyan());
    Ok(())
}

fn show_banner() {
    println!("\n{}", "▄▄▄█████▓▓█████▄  ▒█████  ".bright_cyan());
    println!("{}", "▓  ██▒ ▓▒▒██▀ ██▌▒██▒  ██▒".bright_cyan());
    println!("{}", "▒ ▓██░ ▒░░██   █▌▒██░  ██▒".bright_cyan());
    println!("{}", "░ ▓██▓ ░ ░▓█▄   ▌▒██   ██░".bright_cyan());
    println!("{}", "  ▒██▒ ░ ░▒████▓ ░ ████▓▒░".bright_cyan());
    println!("{}", "  ▒ ░░    ▒▒▓  ▒ ░ ▒░▒░▒░ ".bright_cyan());
    println!("{}", "    ░     ░ ▒  ▒   ░ ▒ ▒░ ".bright_cyan());
    println!("{}", "  ░       ░ ░  ░ ░ ░ ░ ▒  ".bright_cyan());
    println!("{}", "            ░        ░ ░  ".bright_cyan());
    println!("{}", "          ░               ".bright_cyan());
    println!();
}
