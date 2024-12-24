if not FluidUIStay then
  -- FluidUIStay (table) is empty
  -- media\lua\client\Fluids\ISFluidTransferUI.lua
  FluidUIStay = {}
  FluidUIStay.orgISFluidTransferUIOpenPanel = ISFluidTransferUI.OpenPanel 
  FluidUIStay.orgISFluidTransferUIcreateChildren = ISFluidTransferUI.createChildren
end

function FluidUIStay.swap(ui)
  local tmp = ui.panelLeft;
  
  ui.panelLeft = ui.panelRight;
  ui.panelLeft:setX(ui.panelLeftX);
  ui.panelLeft:setIsLeft(true);
  
  ui.panelRight = tmp;
  ui.panelRight:setX(ui.panelRightX);
  ui.panelRight:setIsLeft(false);

  ui:validatePanel();
end

-- Overwrite: ISFluidTransferUI.OpenPanel
function ISFluidTransferUI.OpenPanel(_player, _container, _source) -- void
  -- call original
  FluidUIStay.orgISFluidTransferUIOpenPanel(_player, _container, _source);
  
  -- reset pos properly
  local playerNum = _player:getPlayerNum();
  local ui = ISFluidTransferUI.players[playerNum].instance;
  
  if ui and ISFluidTransferUI.players[playerNum].x and ISFluidTransferUI.players[playerNum].y then
    ui:setX(ISFluidTransferUI.players[playerNum].x);
    ui:setY(ISFluidTransferUI.players[playerNum].y);
  end
end

function ISFluidTransferUI:createChildren()
  -- call original
  FluidUIStay.orgISFluidTransferUIcreateChildren(self);

  -- FIX: an empty container should go right side (target), otherwise left side (source)
  -- this is currently (42.0.2) reversed for some reason (ISFluidTransferUI.lua:107):
  local panelLeft = self.panelLeft;

  if panelLeft then
    local leftFluidContainer = panelLeft:getContainer();
    
    if leftFluidContainer and leftFluidContainer:isEmpty() then
      -- swap panels left/right, if left container is empty (how would this ever be the source...)
      FluidUIStay.swap(self)
    else -- left slot is empty, put right to left, if not empty
      local rightFluidContainer = self.panelRight:getContainer();
      
      if rightFluidContainer and not rightFluidContainer:isEmpty() then
        FluidUIStay.swap(self)
      end
    end
  end
end
