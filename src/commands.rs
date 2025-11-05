use clap::{Arg, Command};

pub fn build_cli() -> Command {
    Command::new("tdo")
        .about("🦀 Rust-powered CLI To-Do App")
        .version("1.0")
        .author("Jit Mukherjee")
        .arg_required_else_help(false) 
        .subcommand_required(false)    
        .subcommand(
            Command::new("add")
                .about("Add a new task")
                .arg(Arg::new("title").required(true))
                .arg(
                    Arg::new("due")
                        .long("due")
                        .short('d')
                        .help("Set a due date (YYYY-MM-DD)")
                        .num_args(1),
                )
                .arg(
                    Arg::new("repeat")
                        .long("repeat")
                        .short('r')
                        .help("Repeat interval (daily, weekly, etc.)")
                        .num_args(1),
                ),
        )
        .subcommand(Command::new("list").about("List all tasks"))
        .subcommand(
            Command::new("done")
                .about("Mark a task as done")
                .arg(Arg::new("id").required(true)),
        )
        .subcommand(
            Command::new("delete")
                .about("Delete a task")
                .arg(Arg::new("id").required(true)),
        )
        .subcommand(Command::new("reset").about("Delete all tasks"))
}
