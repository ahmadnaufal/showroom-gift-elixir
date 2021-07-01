defmodule ShowroomGift.ShowroomClient do
  alias Finch.Response
  alias ShowroomGift.GiftResponse

  @base_url "https://www.showroom-live.com"
  @gifting_free_url "https://www.showroom-live.com/api/live/gifting_free"
  @gifting_point_use_url "https://www.showroom-live.com/api/live/gifting_point_use"

  @gifts_free [1,2,1001,1002,1003,1501,1502,1503,1504,1505]

  def child_spec do
    {Finch,
     name: __MODULE__,
     pools: %{
      @base_url => [size: pool_size()]
     }}
  end

  def pool_size, do: 5

  def post_gift(post_body, gift_id) when (gift_id in @gifts_free) do
    Finch.build(:post, @gifting_free_url, headers(), post_body)
    |> Finch.request(__MODULE__)
  end

  def post_gift(post_body, _) do
    Finch.build(:post, @gifting_point_use_url, headers(), post_body)
    |> Finch.request(__MODULE__)
  end

  def parse_response({:ok, %Response{body: body}}) do
    body
    |> Jason.decode!
    |> case do
      %{"errors" => errors} ->
        %GiftResponse{errors: errors}

      %{
        "gift_id" => gift_id,
        "gift_name" => gift_name,
        "bonus_rate" => bonus_rate,
        "notify_level_up" => notify_level_up,
        "add_point" => add_point,
       } ->
        %GiftResponse{
          gift_id: gift_id,
          gift_name: gift_name,
          bonus_rate: bonus_rate,
          level_up: notify_level_up,
          add_point: add_point
        }

      %{
        "gift_id" => gift_id,
        "gift_name" => gift_name,
        "notify_level_up" => notify_level_up,
        "use_gold" => use_gold,
       } ->
        %GiftResponse{
          gift_id: gift_id,
          gift_name: gift_name,
          level_up: notify_level_up,
          use_gold: use_gold
        }

      _ ->
        raise "Unknown response received"
    end
  end

  def submit_gift(%{
    "gift_id" => gift_id,
    "size" => size,
    "live_id" => live_id,
    "csrf_token" => csrf_token
  }) do
    %{
      "gift_id" => gift_id,
      "num" => size,
      "live_id" => live_id,
      "csrf_token" => csrf_token,
      "isRemovable" => true
    }
    |> URI.encode_query
    |> post_gift(gift_id)
    |> parse_response
  end

  defp headers do
    [
      {"User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:83.0) Gecko/20100101 Firefox/83.0"},
      {"Accept", "*/*"},
      {"Accept-Language", "en-US,en;q=0.5"},
      {"Content-Type", "application/x-www-form-urlencoded; charset=UTF-8"},
      {"X-Requested-With", "XMLHttpRequest"},
      {"Origin", "https://www.showroom-live.com"},
      {"Connection", "keep-alive"},
      {"Cookie", ""}
    ]
  end
end