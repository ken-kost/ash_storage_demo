defmodule AshStorageDemo.Storage.Blob do
  use Ash.Resource,
    domain: AshStorageDemo.Storage,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshStorage.BlobResource, AshOban]

  postgres do
    table "storage_blobs"
    repo AshStorageDemo.Repo
  end

  blob do
  end

  oban do
    triggers do
      trigger :purge_blob do
        action :purge_blob
        read_action :read
        where expr(pending_purge == true)
        scheduler_cron "* * * * *"
        max_attempts 3
        scheduler_module_name AshStorageDemo.Storage.Blob.PurgeBlobScheduler
        worker_module_name AshStorageDemo.Storage.Blob.PurgeBlobWorker
      end

      trigger :run_pending_variants do
        action :run_pending_variants
        read_action :read
        where expr(pending_variants == true)
        scheduler_cron "* * * * *"
        max_attempts 3
        scheduler_module_name AshStorageDemo.Storage.Blob.RunPendingVariantsScheduler
        worker_module_name AshStorageDemo.Storage.Blob.RunPendingVariantsWorker
      end

      trigger :run_pending_analyzers do
        action :run_pending_analyzers
        read_action :read
        where expr(pending_analyzers == true)
        scheduler_cron "* * * * *"
        max_attempts 3
        scheduler_module_name AshStorageDemo.Storage.Blob.RunPendingAnalyzersScheduler
        worker_module_name AshStorageDemo.Storage.Blob.RunPendingAnalyzersWorker
      end
    end
  end

  attributes do
    uuid_primary_key :id
  end
end
