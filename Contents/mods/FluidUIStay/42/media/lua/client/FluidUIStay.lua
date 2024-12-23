FluidUIStay = {}
FluidUIStay.ISFluidTransferUIOpenPanel = ISFluidTransferUI.OpenPanel -- media\lua\client\Fluids\ISFluidTransferUI.lua

-- Overwrite: ISFluidTransferUI.OpenPanel
function ISFluidTransferUI.OpenPanel(_player, _container, _source) -- void
  -- call original
  FluidUIStay.ISFluidTransferUIOpenPanel(_player, _container, _source);
  
  -- reset pos properly
  local playerNum = _player:getPlayerNum();
  local ui = ISFluidTransferUI.players[playerNum].instance;
  
  if ui and ISFluidTransferUI.players[playerNum].x and ISFluidTransferUI.players[playerNum].y then
    ui:setX(ISFluidTransferUI.players[playerNum].x);
    ui:setY(ISFluidTransferUI.players[playerNum].y);
  end
end
