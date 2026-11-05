--- @since 26.5.6

local toggle_ui = ya.sync(function(self)
	if self.children then
		Modal:children_remove(self.children)
		self.children = nil
	else
		self.children = Modal:children_add(self, 10)
	end
	if ui.render then ui.render() else ya.render() end
end)

local subscribe = ya.sync(function(self)
	ps.unsub("mount")
	ps.sub("mount", function()
		ya.emit("plugin", { "mount", "refresh" })
	end)
end)

local update_partitions = ya.sync(function(self, partitions)
	self.partitions = partitions
	if not self.cursor then
		local first_choice = 0
		for i, p in ipairs(partitions) do
			if p.is_removable or (not p.is_disk) then
				first_choice = i - 1
				break
			end
		end
		self.cursor = first_choice
	else
		self.cursor = math.max(0, math.min(self.cursor, #self.partitions - 1))
	end
	if ui.render then ui.render() else ya.render() end
end)

local active_partition = ya.sync(function(self)
	return self.partitions and self.partitions[(self.cursor or 0) + 1]
end)

local update_cursor = ya.sync(function(self, cursor)
	if not self.partitions or #self.partitions == 0 then
		self.cursor = 0
	else
		self.cursor = ya.clamp(0, (self.cursor or 0) + cursor, #self.partitions - 1)
	end
	if ui.render then ui.render() else ya.render() end
end)

local M = {
	keys = {
		{ on = "q", run = "quit" },
		{ on = "<Esc>", run = "quit" },
		{ on = "<Enter>", run = { "enter", "quit" } },
		{ on = "l", run = { "enter", "quit" } },
		{ on = "<Right>", run = { "enter", "quit" } },

		{ on = "k", run = "up" },
		{ on = "j", run = "down" },
		{ on = "<Up>", run = "up" },
		{ on = "<Down>", run = "down" },

		{ on = "m", run = "mount" },
		{ on = "u", run = "unmount" },
		{ on = "e", run = "eject" },
		{ on = "r", run = "refresh" },
	},
}

function M:new(area)
	self:layout(area)
	return self
end

function M:layout(area)
	local v_chunks = ui.Layout()
		:constraints({
			ui.Constraint.Percentage(10),
			ui.Constraint.Percentage(80),
			ui.Constraint.Percentage(10),
		})
		:split(area)

	local h_chunks = ui.Layout()
		:direction(ui.Layout.HORIZONTAL)
		:constraints({
			ui.Constraint.Percentage(10),
			ui.Constraint.Percentage(80),
			ui.Constraint.Percentage(10),
		})
		:split(v_chunks[2])

	self._area = h_chunks[2]
end

function M:entry(job)
	if job.args[1] == "refresh" then
		return update_partitions(self.obtain())
	end

	toggle_ui()
	update_partitions(self.obtain())
	subscribe()

	local tx1, rx1 = ya.chan("mpsc")
	local tx2, rx2 = ya.chan("mpsc")

	function producer()
		while true do
			local cand = self.keys[ya.which { cands = self.keys, silent = true }] or { run = {} }
			for _, r in ipairs(type(cand.run) == "table" and cand.run or { cand.run }) do
				tx1:send(r)
				if r == "quit" then
					toggle_ui()
					return
				end
			end
		end
	end

	function consumer1()
		repeat
			local run = rx1:recv()
			if run == "quit" then
				tx2:send(run)
				break
			elseif run == "up" then
				update_cursor(-1)
			elseif run == "down" then
				update_cursor(1)
			elseif run == "refresh" then
				update_partitions(self.obtain())
			elseif run == "enter" then
				local active = active_partition()
				if not active then
					-- rien
				elseif active.mountpoint and active.mountpoint ~= "" then
					ya.emit("cd", { active.mountpoint })
				elseif active.is_disk and active.has_children then
					ya.notify { title = "Information", content = "Sélectionnez une partition à ouvrir", timeout = 3 }
				elseif active.path then
					local output, err = Command("udisksctl"):arg({ "mount", "-b", active.path }):output()
					if output and output.status.success then
						local mnt = output.stdout:match("at%s+(.-)%s*%.?\n?$")
						if not mnt or mnt == "" then
							local res = Command("lsblk"):arg({ "-n", "-o", "MOUNTPOINT", active.path }):output()
							if res and res.stdout then
								mnt = res.stdout:match("^%s*(.-)%s*$")
							end
						end
						if mnt and mnt ~= "" then
							ya.notify { title = "Disque monté", content = "Ouverture de " .. mnt, timeout = 3 }
							ya.emit("cd", { mnt })
						else
							ya.notify { title = "Monté", content = "Périphérique monté avec succès", timeout = 3 }
						end
					else
						local msg = (output and output.stderr and output.stderr ~= "") and output.stderr or (err or "Échec du montage")
						msg = msg:gsub("^Error looking up object for device assuming command is object path: ", "")
						ya.notify { title = "Erreur de montage", content = msg, timeout = 5, level = "error" }
					end
				end
			else
				tx2:send(run)
			end
		until not run
	end

	function consumer2()
		repeat
			local run = rx2:recv()
			if run == "quit" then
				break
			elseif run == "mount" then
				local active = active_partition()
				if not active or not active.path then
					--
				elseif active.mountpoint and active.mountpoint ~= "" then
					ya.notify { title = "Information", content = "Déjà monté sur " .. active.mountpoint, timeout = 3 }
				elseif active.is_disk and active.has_children then
					ya.notify { title = "Information", content = "Sélectionnez une partition à monter", timeout = 3 }
				else
					local output, err = Command("udisksctl"):arg({ "mount", "-b", active.path }):output()
					if output and output.status.success then
						local mnt = output.stdout:match("at%s+(.-)%s*%.?\n?$")
						ya.notify { title = "Montage réussi", content = "Monté sur " .. (mnt or active.path), timeout = 3 }
						update_partitions(self.obtain())
					else
						local msg = (output and output.stderr and output.stderr ~= "") and output.stderr or (err or "Échec du montage")
						msg = msg:gsub("^Error looking up object for device assuming command is object path: ", "")
						ya.notify { title = "Erreur de montage", content = msg, timeout = 5, level = "error" }
					end
				end
			elseif run == "unmount" then
				local active = active_partition()
				if not active or not active.path then
					--
				elseif not active.mountpoint or active.mountpoint == "" then
					ya.notify { title = "Information", content = "Ce périphérique n'est pas monté", timeout = 3 }
				else
					local output, err = Command("udisksctl"):arg({ "unmount", "-b", active.path }):output()
					if output and output.status.success then
						ya.notify { title = "Démontage réussi", content = "Démonté: " .. (active.label ~= "" and active.label or active.name), timeout = 3 }
						update_partitions(self.obtain())
					else
						local msg = (output and output.stderr and output.stderr ~= "") and output.stderr or (err or "Échec du démontage")
						msg = msg:gsub("^Error looking up object for device assuming command is object path: ", "")
						ya.notify { title = "Erreur de démontage", content = msg, timeout = 5, level = "error" }
					end
				end
			elseif run == "eject" then
				local active = active_partition()
				if not active or not active.path then
					--
				else
					local target_path = active.parent_path or active.path
					if active.mountpoint and active.mountpoint ~= "" then
						Command("udisksctl"):arg({ "unmount", "-b", active.path }):output()
					end
					local output, err = Command("udisksctl"):arg({ "power-off", "-b", target_path }):output()
					if output and output.status.success then
						ya.notify { title = "Éjection réussie", content = "Le lecteur peut être retiré en toute sécurité", timeout = 4 }
						update_partitions(self.obtain())
					else
						local o2, _ = Command("eject"):arg({ target_path }):output()
						if o2 and o2.status.success then
							ya.notify { title = "Éjection réussie", content = "Lecteur éjecté", timeout = 4 }
							update_partitions(self.obtain())
						else
							local msg = (output and output.stderr and output.stderr ~= "") and output.stderr or (err or "Échec de l'éjection")
							msg = msg:gsub("^Error looking up object for device assuming command is object path: ", "")
							ya.notify { title = "Erreur éjection", content = msg, timeout = 5, level = "error" }
						end
					end
				end
			end
		until not run
	end

	ya.join(producer, consumer1, consumer2)
end

function M:reflow() return { self } end

function M:redraw()
	local rows = {}
	for _, p in ipairs(self.partitions or {}) do
		local name_col = p.name or ""
		if p.is_child then
			name_col = "  " .. name_col
		end

		if p.is_removable then
			name_col = "󱊞 " .. name_col
		elseif p.is_disk then
			name_col = "󰋊 " .. name_col
		else
			name_col = "  " .. name_col
		end

		local style = ui.Style()
		local mnt_str
		if p.mountpoint and p.mountpoint ~= "" then
			style = style:fg("green")
			mnt_str = "● " .. p.mountpoint
		else
			if p.is_disk then
				mnt_str = ""
			else
				style = style:fg("darkgray")
				mnt_str = "○ non monté"
			end
		end

		local label_style = ui.Style()
		if p.label and p.label ~= "" then
			label_style = label_style:fg("yellow"):bold()
		end

		rows[#rows + 1] = ui.Row({
			ui.Line(name_col),
			ui.Line(p.size or ""):style(ui.Style():fg("cyan")),
			ui.Line(p.fstype or ""):style(ui.Style():fg("magenta")),
			ui.Line(p.label ~= "" and p.label or "-"):style(label_style),
			ui.Line(mnt_str):style(style),
		})
	end

	return {
		ui.Clear(self._area),
		ui.Border(ui.Edge.ALL)
			:area(self._area)
			:type(ui.Border.ROUNDED)
			:style(ui.Style():fg("blue"))
			:title(ui.Line(" 󰋊 Disques & Volumes amovibles [Entrée: Ouvrir | m: Monter | u: Démonter | e: Éjecter] "):align(ui.Align.CENTER)),
		ui.Table(rows)
			:area(self._area:pad(ui.Pad(1, 1, 1, 1)))
			:header(ui.Row({ "Périphérique", "Taille", "Système", "Label", "Point de montage" }):style(ui.Style():bold():fg("lightgray")))
			:row(self.cursor or 0)
			:row_style(ui.Style():fg("blue"):underline())
			:widths({
				ui.Constraint.Length(18),
				ui.Constraint.Length(10),
				ui.Constraint.Length(10),
				ui.Constraint.Length(18),
				ui.Constraint.Fill(1),
			}),
	}
end

local function parse_devices(devices, result, depth, parent_path)
	if not devices then return end
	for _, dev in ipairs(devices) do
		local valid = true
		if dev.type == "loop" or dev.type == "rom" or dev.type == "ram" then
			valid = false
		elseif dev.fstype == "swap" then
			valid = false
		elseif dev.size == "0B" and (not dev.children or #dev.children == 0) then
			valid = false
		end

		if valid then
			local has_children = dev.children and #dev.children > 0
			local mnt = dev.mountpoint
			if type(mnt) == "table" then
				mnt = table.concat(mnt, ", ")
			end

			table.insert(result, {
				name = dev.name or "",
				path = dev.path or ("/dev/" .. (dev.name or "")),
				label = dev.label or "",
				fstype = dev.fstype or "",
				mountpoint = mnt,
				size = dev.size or "",
				type = dev.type or "",
				is_removable = dev.rm == true,
				is_child = depth > 0,
				has_children = has_children,
				is_disk = dev.type == "disk" and has_children,
				parent_path = parent_path or (dev.type == "disk" and dev.path or nil),
			})

			if has_children then
				parse_devices(dev.children, result, depth + 1, dev.path)
			end
		end
	end
end

function M.obtain()
	if ya.target_os() ~= "linux" then return {} end

	local output, err = Command("lsblk")
		:arg("-J")
		:arg("-o")
		:arg("NAME,PATH,LABEL,FSTYPE,MOUNTPOINT,SIZE,TYPE,RM")
		:output()

	if not output or not output.stdout or output.stdout == "" then
		ya.notify({ title = "Disques", content = "Erreur de lecture lsblk", level = "error" })
		return {}
	end

	local json = ya.json_decode(output.stdout)
	if not json or not json.blockdevices then return {} end

	local tbl = {}
	parse_devices(json.blockdevices, tbl, 0, nil)
	return tbl
end

function M:click() end
function M:scroll() end
function M:touch() end

return M
