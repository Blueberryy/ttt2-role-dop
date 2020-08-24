util.AddNetworkString("ttt2_dop_popup")
local function DoppelChange(ply, key)
  if not DOPPELGANGER then return end
  if not IsValid(ply) or not ply:IsPlayer() then return end
  if ply:GetSubRole() ~= ROLE_MIMIC and ply:GetSubRole() ~= ROLE_DOPPELGANGER then return end

  if key ~= IN_USE then return end

  local trace = ply:GetEyeTrace(MASK_SHOT_HULL)
  local distance = trace.StartPos:Distance(trace.HitPos)
  local tgt = trace.Entity

  if distance > 100 or not IsValid(tgt) or not tgt:IsPlayer() then return end

  local new_role = tgt:GetSubRole()
  local new_team = tgt:GetTeam()
  local did_steal = true

  if ply:GetSubRole() == ROLE_DOPPELGANGER then
    new_team = TEAM_DOPPELGANGER
  end

  new_role, new_team, did_steal = hook.Run("TTT2DoppelgangerRoleChange", ply, new_role, new_team, did_steal)

  ply:SetRole(new_role, new_team)
  SendFullStateUpdate()

  if not did_steal then return end
  local steal_mode = GetConVar("ttt2_dop_steal_role")

  if steal_mode and AMNESIAC then
    tgt:SetRole(ROLE_AMNESIAC, TEAM_NONE)
  end
  SendFullStateUpdate()

  local popup_mode = GetConVar("ttt2_dop_declare_mode")

  if popup_mode == 1 or (popup_mode ~= 2 and steal_mode) then
    net.Start("ttt2_dop_popup")
    net.WriteEntity(tgt)
    net.WriteEntity(ply)
    net.WriteBool(steal_mode)
    net.Send(tgt)
  elseif popup_mode == 2 then
    net.Start("ttt2_dop_popup")
    net.WriteEntity(tgt)
    net.WriteEntity(ply)
    net.WriteBool(steal_mode)
    net.Broadcast()
  end

end

hook.Add("KeyPress", "TTT2DoppelChange", DoppelChange)

local function DoppelMarker(ply, new_role, new_team, did_steal)
  if not MARKER then return end
  if not IsValid(ply) or ply:IsSpec() or not ply:Alive() then return end
  if ply:GetSubRole() ~= ROLE_DOPPELGANGER and ply:GetSubRole() ~= ROLE_MIMIC then return end
  if new_role ~= ROLE_MARKER then return end
  did_steal = false

  if AMNESIAC then
    new_role = ROLE_AMNESIAC
    new_team = TEAM_NONE
  elseif UNKNOWN then
    new_role = ROLE_UNKNOWN
    new_team = TEAM_NONE
  else
    new_role = ROLE_INNOCENT
    new_team = TEAM_INNOCENT
  end

  if MARKER_DATA then MARKER_DATA:SetMarkedPlayer(ply) end

  return new_role, new_team, did_steal
end

hook.Add("TTT2DoppelgangerRoleChange", "TTT2DoppelMarker", DoppelMarker)
