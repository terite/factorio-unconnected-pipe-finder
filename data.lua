arrow = util.table.deepcopy(data.raw["arrow"]["orange-arrow-with-circle"])
arrow.name = "orphan-arrow"
arrow.circle_picture =
{
  filename = "__Unconnected Pipe Finder__/graphics/large-orange-circle.png",
  priority = "low",
  width = "64",
  height = "64"
}

data:extend({
  arrow,
  {
    type = "custom-input",
    name = "toggle-show-unconnected-pipe",
    key_sequence = "SHIFT + U"
  }
})