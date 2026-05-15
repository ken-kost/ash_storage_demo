defmodule AshStorageDemoWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use AshStorageDemoWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint AshStorageDemoWeb.Endpoint

      use AshStorageDemoWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest
      import AshStorageDemoWeb.ConnCase
      import AshStorageDemo.Fixtures
    end
  end

  setup tags do
    AshStorageDemo.DataCase.setup_sandbox(tags)
    AshStorage.Service.Test.reset!()
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Builds a conn the auth plugs will treat as a signed-in user. Mints a
  JWT directly via `AshAuthentication.Jwt.token_for_user/2` (the User
  resource has `require_token_presence_for_authentication? true`, so a
  real token has to land in the token table), then puts it in session.
  """
  def log_in_user(conn, user) do
    {:ok, token, _claims} = AshAuthentication.Jwt.token_for_user(user)
    user_with_token = Ash.Resource.put_metadata(user, :token, token)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> AshAuthentication.Plug.Helpers.store_in_session(user_with_token)
  end
end
