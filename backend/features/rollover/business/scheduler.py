"""
Rollover scheduler: automated periodic rollover checks.

Sets up APScheduler to run rollover checks hourly and once immediately
on application startup (for catch-up on server restart).
"""

from apscheduler.schedulers.asyncio import AsyncIOScheduler
import logging

logger = logging.getLogger(__name__)

# Global scheduler instance
scheduler: AsyncIOScheduler | None = None


async def setup_rollover_scheduler(run_check_fn) -> AsyncIOScheduler:
    """
    Set up and start the rollover scheduler with APScheduler.

    This function initializes and starts an AsyncIOScheduler that:
    1. Runs run_check_fn() immediately on startup (catch-up behavior).
    2. Runs run_check_fn() hourly on an interval schedule.

    Args:
        run_check_fn: An async callable that performs the rollover check for all users.
                      Signature: async def run_check_fn() -> None

    Returns:
        The started AsyncIOScheduler instance.
    """
    global scheduler

    # Create the scheduler
    scheduler = AsyncIOScheduler()

    # Add immediate job (catch-up on startup)
    scheduler.add_job(
        run_check_fn,
        "date",
        run_date=None,  # Run immediately
        id="rollover_startup_catchup",
        name="Rollover startup catch-up",
        replace_existing=True,
    )

    # Add hourly job
    scheduler.add_job(
        run_check_fn,
        "interval",
        hours=1,
        id="rollover_hourly",
        name="Rollover hourly check",
        replace_existing=True,
    )

    # Start the scheduler
    scheduler.start()
    logger.info("Rollover scheduler started with hourly and startup catch-up jobs")

    return scheduler


async def shutdown_scheduler() -> None:
    """Shutdown the rollover scheduler."""
    global scheduler
    if scheduler and scheduler.running:
        scheduler.shutdown()
        logger.info("Rollover scheduler shut down")


def setup_scheduler(app_lifespan_context, run_check_fn) -> None:
    """
    Set up the rollover scheduler with APScheduler (legacy interface).

    This function initializes and starts an AsyncIOScheduler that:
    1. Runs run_check_fn() immediately on startup (catch-up behavior).
    2. Runs run_check_fn() hourly on an interval schedule.

    Args:
        app_lifespan_context: The FastAPI lifespan context (or similar async context manager)
                              to attach scheduler startup/shutdown hooks. In FastAPI,
                              this is the `lifespan` function in create_app().
        run_check_fn: An async callable that performs the rollover check for all users.
                      Signature: async def run_check_fn() -> None

    Returns:
        None

    Implementation note:
        - Create an AsyncIOScheduler instance.
        - Add a job that runs run_check_fn() immediately.
        - Add an interval job that runs run_check_fn() every hour.
        - Register scheduler.start() in the lifespan startup.
        - Register scheduler.shutdown() in the lifespan shutdown.
    """
    raise NotImplementedError("Use setup_rollover_scheduler instead")
