// VATS's tab in the scanner's panel (spike V13, docs/design.md).
//
// The panel (scannerDetailsGameController) shows Data and then either Hacking or TwinTone, the
// vehicle paint tab, which an NPC never has. While scanning an NPC, VATS takes TwinTone's slot:
// its header says VATS and moves after Data (Data, VATS, Hacking; Switch Tab cycles in that
// order), and its body shows the scanned enemy's body parts with their hit chances. A car keeps
// TwinTone as the game made it.
//
// The numbers come from VATS's Node mod, through REDnode's api:
//   const panel = await (await api.GameInstance.GetScriptableSystemsContainer(game.instance)).Get('VATS.VATSPanelSystem');
//   await panel.SetPart('Head', 80);
//
// Only redscript and the game's own classes: no Codeware needed.

module VATS

// The six parts and their chances (0 to 100, -1 for not known yet), kept for the panel.
public class VATSPanelSystem extends ScriptableSystem {
  private let m_names: array<String>;
  private let m_chances: array<Int32>;
  private let m_enabled: Bool = true;
  private let m_panel: wref<scannerDetailsGameController>;

  public func OnAttach() -> Void {
    ArrayClear(this.m_names);
    ArrayClear(this.m_chances);
    ArrayPush(this.m_names, "Head");
    ArrayPush(this.m_names, "Torso");
    ArrayPush(this.m_names, "Left arm");
    ArrayPush(this.m_names, "Right arm");
    ArrayPush(this.m_names, "Left leg");
    ArrayPush(this.m_names, "Right leg");
    let i = 0;
    while i < ArraySize(this.m_names) {
      ArrayPush(this.m_chances, -1);
      i += 1;
    }
  }

  public static func Get(game: GameInstance) -> ref<VATSPanelSystem> {
    return GameInstance.GetScriptableSystemsContainer(game).Get(n"VATS.VATSPanelSystem") as VATSPanelSystem;
  }

  // Sets one part's chance (a name from the six, 0 to 100, or -1 for not known) and redraws.
  public func SetPart(name: String, chance: Int32) -> Bool {
    let i = ArrayFindFirst(this.m_names, name);
    if i < 0 {
      return false;
    }
    this.m_chances[i] = chance;
    this.Redraw();
    return true;
  }

  // Every part back to not known (a new enemy).
  public func ClearParts() -> Void {
    let i = 0;
    while i < ArraySize(this.m_chances) {
      this.m_chances[i] = -1;
      i += 1;
    }
    this.Redraw();
  }

  // VATS's tab on or off; off gives the panel back to the game as it was.
  public func SetEnabled(on: Bool) -> Void {
    this.m_enabled = on;
    if IsDefined(this.m_panel) {
      this.m_panel.VATSEnabledChanged();
    }
  }

  public func IsEnabled() -> Bool {
    return this.m_enabled;
  }

  public func PartCount() -> Int32 {
    return ArraySize(this.m_names);
  }

  public func PartName(i: Int32) -> String {
    return this.m_names[i];
  }

  public func PartChance(i: Int32) -> Int32 {
    return this.m_chances[i];
  }

  public func SetPanel(panel: ref<scannerDetailsGameController>) -> Void {
    this.m_panel = panel;
  }

  private func Redraw() -> Void {
    if IsDefined(this.m_panel) {
      this.m_panel.VATSRedraw();
    }
  }
}

// ---------- the panel ----------

@addField(scannerDetailsGameController)
private let m_vatsBody: wref<inkVerticalPanel>;

@addField(scannerDetailsGameController)
private let m_vatsRows: array<wref<inkText>>;

@addField(scannerDetailsGameController)
private let m_vatsTwinToneLabel: String;

@addField(scannerDetailsGameController)
private let m_vatsOrdered: Bool;

// Whether the tab in TwinTone's slot is VATS's now: an NPC scanned, VATS on.
@addMethod(scannerDetailsGameController)
private final func VATSActive() -> Bool {
  if !IsDefined(this.m_player) {
    return false;
  }
  let system = VATSPanelSystem.Get(this.m_player.GetGame());
  return IsDefined(system) && system.IsEnabled() && Equals(this.m_scannedObjectType, ScannerObjectType.PUPPET);
}

@wrapMethod(scannerDetailsGameController)
protected cb func OnInitialize() -> Bool {
  let r = wrappedMethod();
  this.VATSBuildBody();
  return r;
}

@wrapMethod(scannerDetailsGameController)
protected cb func OnPlayerAttach(player: ref<GameObject>) -> Bool {
  let r = wrappedMethod(player);
  let system = VATSPanelSystem.Get(player.GetGame());
  if IsDefined(system) {
    system.SetPanel(this);
  }
  return r;
}

// For an NPC, TwinTone's slot is shown (as VATS).
@wrapMethod(scannerDetailsGameController)
private const final func ShouldDisplayTwintoneTab() -> Bool {
  if this.VATSActive() {
    return true;
  }
  return wrappedMethod();
}

// Data, VATS, Hacking: the game lists Data, then Hacking or TwinTone, never both.
@wrapMethod(scannerDetailsGameController)
private const final func GetAvailablesTabs() -> array<ScannerDetailTab> {
  let tabs = wrappedMethod();
  if this.VATSActive() && !ArrayContains(tabs, ScannerDetailTab.TwinTone) {
    ArrayInsert(tabs, 1, ScannerDetailTab.TwinTone);
  }
  return tabs;
}

// The game counts Hacking or TwinTone, not both.
@wrapMethod(scannerDetailsGameController)
private final func GetNumberOfTabsDiplayed() -> Int32 {
  let n = 1;
  if inkWidgetRef.IsVisible(this.m_toggleDescirptionHackPart) {
    n += 1;
  }
  if inkWidgetRef.IsVisible(this.m_toggleDescriptionTwintonePart) {
    n += 1;
  }
  return n;
}

// With three tabs in VATS's order the bottom line under each is: Data 01, VATS 02, Hacking 03.
@wrapMethod(scannerDetailsGameController)
private final func UpdateTabBottomLine() {
  wrappedMethod();
  if !this.VATSActive() || this.GetNumberOfTabsDiplayed() != 3 {
    return;
  }
  inkWidgetRef.SetVisible(this.m_threetabs01BottomLine, Equals(this.m_currentTab, ScannerDetailTab.Data));
  inkWidgetRef.SetVisible(this.m_threetabs02BottomLine, Equals(this.m_currentTab, ScannerDetailTab.TwinTone));
  inkWidgetRef.SetVisible(this.m_threetabs03BottomLine, Equals(this.m_currentTab, ScannerDetailTab.Hacking));
}

// Each time the header changes: the third tab's name, its place, and its body.
@wrapMethod(scannerDetailsGameController)
private final func ToggleTwintoneVisibility() {
  wrappedMethod();
  this.VATSRefreshTabs();
}

@wrapMethod(scannerDetailsGameController)
private final func ToggleQHTabVisibility() {
  wrappedMethod();
  this.VATSRefreshTabs();
}

// VATS switched on or off: the game shows or hides the third header, then VATS sets it up.
@addMethod(scannerDetailsGameController)
public final func VATSEnabledChanged() {
  this.ToggleTwintoneVisibility();
  this.RefreshLayout();
}

@addMethod(scannerDetailsGameController)
public final func VATSRefreshTabs() {
  let active = this.VATSActive();
  this.VATSOrder(active);
  this.VATSLabel(active);
  if IsDefined(this.m_vatsBody) {
    this.m_vatsBody.SetVisible(active);
  }
  this.VATSShowTwinToneBody(!active);
  if active {
    this.VATSRedraw();
  }
}

// Data, space, VATS, space, Hacking when on; the game's own order when off.
@addMethod(scannerDetailsGameController)
private final func VATSOrder(on: Bool) {
  let vats = inkWidgetRef.Get(this.m_toggleDescriptionTwintonePart);
  let hack = inkWidgetRef.Get(this.m_toggleDescirptionHackPart);
  let space1 = inkWidgetRef.Get(this.m_spaceTab01);
  let space2 = inkWidgetRef.Get(this.m_spaceTab02);
  if !IsDefined(vats) || !IsDefined(hack) {
    return;
  }
  let tabs = vats.GetParentWidget() as inkCompoundWidget;
  if !IsDefined(tabs) || Equals(this.m_vatsOrdered, on) {
    return;
  }
  if on {
    tabs.ReorderChild(space2, 1);
    tabs.ReorderChild(vats, 2);
    tabs.ReorderChild(space1, 3);
    tabs.ReorderChild(hack, 4);
  } else {
    tabs.ReorderChild(space1, 1);
    tabs.ReorderChild(hack, 2);
    tabs.ReorderChild(space2, 3);
    tabs.ReorderChild(vats, 4);
  }
  this.m_vatsOrdered = on;
}

// The third tab's text says VATS for an NPC and the game's own word otherwise.
@addMethod(scannerDetailsGameController)
private final func VATSLabel(on: Bool) {
  let header = inkWidgetRef.Get(this.m_toggleDescriptionTwintonePart) as inkCompoundWidget;
  if !IsDefined(header) {
    return;
  }
  let texts: array<wref<inkText>>;
  VATSTexts(header, texts);
  let i = 0;
  while i < ArraySize(texts) {
    if on {
      if StrLen(this.m_vatsTwinToneLabel) == 0 {
        this.m_vatsTwinToneLabel = texts[i].GetText();
      }
      texts[i].SetText("VATS");
    } else {
      if StrLen(this.m_vatsTwinToneLabel) > 0 {
        texts[i].SetText(this.m_vatsTwinToneLabel);
      }
    }
    i += 1;
  }
}

// Every text widget under a widget.
public func VATSTexts(w: wref<inkWidget>, out found: array<wref<inkText>>) {
  let text = w as inkText;
  if IsDefined(text) {
    ArrayPush(found, text);
    return;
  }
  let compound = w as inkCompoundWidget;
  if !IsDefined(compound) {
    return;
  }
  let i = 0;
  while i < compound.GetNumChildren() {
    VATSTexts(compound.GetWidgetByIndex(i), found);
    i += 1;
  }
}

// TwinTone's own body (spawned into twintoneContainer) hidden for an NPC, shown for a car.
@addMethod(scannerDetailsGameController)
private final func VATSShowTwinToneBody(show: Bool) {
  let container = inkWidgetRef.Get(this.m_twintoneContainer) as inkCompoundWidget;
  if !IsDefined(container) {
    return;
  }
  let i = 0;
  while i < container.GetNumChildren() {
    let child = container.GetWidgetByIndex(i);
    if NotEquals(child.GetName(), n"vatsBody") {
      child.SetVisible(show);
    }
    i += 1;
  }
}

// VATS's body: a heading and a row per part, in twintoneContainer.
@addMethod(scannerDetailsGameController)
private final func VATSBuildBody() {
  let container = inkWidgetRef.Get(this.m_twintoneContainer) as inkCompoundWidget;
  if !IsDefined(container) || IsDefined(this.m_vatsBody) {
    return;
  }
  let body = new inkVerticalPanel();
  body.SetName(n"vatsBody");
  body.SetVisible(false);
  body.SetChildMargin(inkMargin(0.0, 6.0, 0.0, 6.0));
  container.AddChildWidget(body);
  this.m_vatsBody = body;
  ArrayClear(this.m_vatsRows);
  let i = 0;
  while i < 6 {
    let row = new inkText();
    row.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
    row.SetFontStyle(n"Medium");
    row.SetFontSize(38);
    row.SetTintColor(HDRColor(1.1761, 0.3809, 0.3476, 1.0));
    row.SetLetterCase(textLetterCase.UpperCase);
    row.SetText("");
    body.AddChildWidget(row);
    ArrayPush(this.m_vatsRows, row);
    i += 1;
  }
}

@addMethod(scannerDetailsGameController)
public final func VATSRedraw() {
  if !IsDefined(this.m_player) {
    return;
  }
  let system = VATSPanelSystem.Get(this.m_player.GetGame());
  if !IsDefined(system) {
    return;
  }
  let i = 0;
  while i < ArraySize(this.m_vatsRows) && i < system.PartCount() {
    let chance = system.PartChance(i);
    let value = chance < 0 ? "--" : IntToString(chance) + "%";
    this.m_vatsRows[i].SetText(system.PartName(i) + "   " + value);
    i += 1;
  }
}
