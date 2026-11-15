// The lit body part and its hit chance, as a line of the game's own UI under the scanned enemy's
// name above the crosshair (the owner, 2026-11-14: tidier than a label beside the body).
//
// The name is the quickhack list's scanner_target_name, in a row (scanner_container: the icon and
// the name) placed straight in the list's screen-sized Root canvas. VATS's line goes into Root too,
// placed as that row is (its anchor, anchor point, margin and offset) and one row lower. It shows
// only while the quickhack list does (a scanned target that can be hacked).
//
// The text comes from VATS's Node mod through REDnode's api:
//   await panel.SetCurrentPart('Left arm', 72); // or ('', -1) to hide it

module VATS

@addField(QuickhacksListGameController)
private let m_vatsPartLine: wref<inkText>;

@wrapMethod(QuickhacksListGameController)
protected cb func OnInitialize() -> Bool {
  let r = wrappedMethod();
  this.VATSBuildPartLine();
  this.VATSRegister();
  return r;
}

// A new target: its name may change the row's height.
@wrapMethod(QuickhacksListGameController)
protected cb func OnTargetDisplayNameChanged(value: Variant) -> Bool {
  let r = wrappedMethod(value);
  this.VATSRegister();
  this.VATSPlacePartLine();
  return r;
}

@addMethod(QuickhacksListGameController)
private final func VATSRegister() {
  let player = this.GetPlayerControlledObject();
  if !IsDefined(player) {
    return;
  }
  let system = VATSPanelSystem.Get(player.GetGame());
  if IsDefined(system) {
    system.SetPartLineOwner(this);
  }
}

@addMethod(QuickhacksListGameController)
private final func VATSBuildPartLine() {
  if IsDefined(this.m_vatsPartLine) {
    return;
  }
  let name = inkWidgetRef.Get(this.m_targetName);
  if !IsDefined(name) {
    return;
  }
  let row = name.GetParentWidget();
  let root = IsDefined(row) ? row.GetParentWidget() as inkCompoundWidget : null;
  if !IsDefined(root) {
    return;
  }
  let line = VATSText(34);
  line.SetName(n"vatsPartLine");
  line.SetFontStyle(n"Semi-Bold");
  line.SetTintColor(HDRColor(0.3725, 0.9608, 0.5608, 1.0));
  line.SetVisible(false);
  root.AddChildWidget(line);
  this.m_vatsPartLine = line;
}

// Where the name's row is, one row lower.
@addMethod(QuickhacksListGameController)
private final func VATSPlacePartLine() {
  let line = this.m_vatsPartLine;
  let name = inkWidgetRef.Get(this.m_targetName);
  if !IsDefined(line) || !IsDefined(name) {
    return;
  }
  let row = name.GetParentWidget();
  if !IsDefined(row) {
    return;
  }
  let height = row.GetDesiredHeight();
  if height < 1.0 {
    height = 48.0;
  }
  let at = row.GetTranslation();
  line.SetAnchor(row.GetAnchor());
  line.SetAnchorPoint(row.GetAnchorPoint());
  line.SetMargin(row.GetMargin());
  line.SetTranslation(at.X, at.Y + height + 6.0);
}

// Shows the text under the name, or hides the line for an empty text.
@addMethod(QuickhacksListGameController)
public final func VATSShowPart(text: String) {
  this.VATSBuildPartLine();
  let line = this.m_vatsPartLine;
  if !IsDefined(line) {
    return;
  }
  if StrLen(text) == 0 {
    line.SetVisible(false);
    return;
  }
  this.VATSPlacePartLine();
  line.SetText(text);
  line.SetVisible(true);
}
