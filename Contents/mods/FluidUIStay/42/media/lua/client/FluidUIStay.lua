FluidUIStay = FluidUIStay or {}

if not FluidUIStay.orgISFluidTransferUIOpenPanel then
  -- FluidUIStay (table) is empty
  -- media\lua\client\Fluids\ISFluidTransferUI.lua
  FluidUIStay.orgISFluidTransferUIOpenPanel = ISFluidTransferUI.OpenPanel 
  FluidUIStay.orgISFluidTransferUIcreateChildren = ISFluidTransferUI.createChildren
  FluidUIStay.orgISFluidContainerPanelclickedDropBox = ISFluidContainerPanel.clickedDropBox
end

-- wrapper/fake function for ISLabel:setName->ISButton:setTitle
local function setNameToTitleWrapper(self, title)
  self:setTitle(title)
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

-- Add an extra handler for our new "Max Transfer"
function FluidUIStay.onButton(ui, btn)
  -- fluidUI=self.parent would probably also work
  ui.slider:setCurrentValue(1.0) -- set slider to max
  ui:validatePanel() -- force validate ui:validatePanel(true)

  -- fake button press the transfer button, if not disabled after the validation
  if not ui.disableTransfer then
    ui:onButton(ui.btnTransfer)
  end
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

-- Overwrite: ISFluidTransferUI:prerender
-- we rewrite the original to draw on self.btnTransfer.parent instead of self,
-- this fixes a rendering bug, where the progress bar is otherwise not properly rendered (over the button)
function ISFluidTransferUI:prerender()
    ISPanelJoypad.prerender(self);

    --draws a background for transfer button and action progress if action exists.
    if self.btnTransfer then
        local x = self.btnTransfer:getX();
        local y = self.btnTransfer:getY();
        local w = self.btnTransfer:getWidth();
        local h = self.btnTransfer:getHeight();
        local parent = self.btnTransfer.parent; -- FIX: we now draw on panelMiddle

        parent:drawRect(x, y, w, h, 1.0, 0, 0, 0);
        self.btnTransfer.backgroundColor.a = 0 -- FIX: I don't know why, but this gets reset somehow -> apply transparency again

        if self.action and self.action.action then
            local c = self.transferColor;
            w = w * self.action:getJobDelta();
            parent:drawRect(x, y, w, h, c.a, c.r, c.g, c.b);
        end
    end
end

function ISFluidTransferUI:createChildren()
  -- call original
  FluidUIStay.orgISFluidTransferUIcreateChildren(self);

  -- FIX: an empty container should go right side (target), otherwise left side (source)
  -- this is currently (last checked 42.6.0) reversed for some reason (ISFluidTransferUI.lua:107):
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

  -- FEATURE: replace the "Max Transfer" label with a button
  if self.maxTransferLabel then
    local c = self.buttonBorderColor;

    self.btnMaxTransfer = ISButton:new(self.btnSwap.x, self.maxTransferLabel.y-3, self.btnSwap.width, self.btnSwap.height, self.maxTransferText, self, nil);
    self.btnMaxTransfer:initialise();
    self.btnMaxTransfer:instantiate();
    self.btnMaxTransfer.backgroundColor.a = 0;
    self.btnMaxTransfer.borderColor = {r=c.r, g=c.g,b=c.b,a=c.a};
    self.btnMaxTransfer:setOnClick(FluidUIStay.onButton, self)

    -- wrapper for ISLabel func
    self.btnMaxTransfer.setName = setNameToTitleWrapper
    local parent = self.maxTransferLabel.parent
    
    if parent then
      parent:addChild(self.btnMaxTransfer);
      -- remove the label, replace the reference to it with our button
      parent:removeChild(self.maxTransferLabel)
      self.maxTransferLabel = self.btnMaxTransfer
    end
  end
end

function ISFluidContainerPanel:clickedDropBox(x, y)
  -- call original
  FluidUIStay.orgISFluidContainerPanelclickedDropBox(self, x, y)

  -- post process: add item icons to existing context menu
  local playerNum = self.player:getPlayerNum()
  local context = getPlayerContextMenu(playerNum)

  if not context or context:isEmpty() then
    return
  end

  for _, opt in ipairs(context.options) do
    local item = opt.param1

    if item then
      opt.itemForTexture = item
    end
  end

  -- the context's size now likely changed because of the icons, let's resize+position
  local parent = self.parent -- ISFluidContainerPanel
  local parentUI = parent.parent -- ISFluidInfoUI/ISFluidTransferUI
  local xx = parentUI:getAbsoluteX() + parentUI:getWidth()
  local yy = parentUI:getAbsoluteY() + parent:getY()

  context:setWidth(context:calcWidth())
  context:calcHeight()

  if parent.isLeft then
    xx = parentUI:getAbsoluteX() - context:getWidth()
    context:setSlideGoalX(xx - 20, xx)
  else
    context:setSlideGoalX(xx + 20, xx)
  end

  context:setSlideGoalY(yy - 10, yy)
  context:bringToTop()
end
