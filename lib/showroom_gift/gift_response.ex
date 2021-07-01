defmodule ShowroomGift.GiftResponse do
  defstruct [
    :errors,
    gift_id: 0,
    gift_name: "",
    bonus_rate: 0.0,
    level_up: false,
    use_gold: 0,
    add_point: 0
  ]
end