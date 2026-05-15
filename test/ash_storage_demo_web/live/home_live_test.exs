defmodule AshStorageDemoWeb.HomeLiveTest do
  use AshStorageDemoWeb.ConnCase, async: false

  describe "guest view" do
    test "renders the hero + module tile grid", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/")
      assert html =~ "ash"
      assert html =~ "storage"
      assert html =~ "Storage that knows"
      assert has_element?(view, "[data-role='tile-feed']")
      assert has_element?(view, "[data-role='tile-profile']")
      assert has_element?(view, "[data-role='tile-storage']")
    end

    test "shows Sign in + Register CTAs and no Feed link in nav", %{conn: conn} do
      {:ok, view, _} = live(conn, ~p"/")
      assert has_element?(view, "[data-role='home-cta-sign-in']")
      assert has_element?(view, "[data-role='home-cta-register']")
      assert has_element?(view, "[data-role='nav-sign-in']")
      refute has_element?(view, "[data-role='nav-feed']")
      refute has_element?(view, "[data-role='nav-sign-out']")
    end
  end

  describe "signed-in view" do
    setup %{conn: conn} do
      {:ok, conn: log_in_user(conn, user())}
    end

    test "swaps Sign-in CTA for the Feed CTA + adds nav links", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      assert has_element?(view, "[data-role='home-cta-feed']")
      assert has_element?(view, "[data-role='nav-feed']")
      assert has_element?(view, "[data-role='nav-profile']")
      assert has_element?(view, "[data-role='nav-storage-admin']")
      assert has_element?(view, "[data-role='nav-sign-out']")
      refute has_element?(view, "[data-role='nav-sign-in']")
    end
  end
end
