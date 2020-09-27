-- видеоскрипт для плейлиста "mediabay" http://mediabay.tv (9/2/20)
-- открывает подобные ссылки:
-- http://mediabay.tv/tv/499
		if m_simpleTV.Control.ChangeAddress ~= 'No' then return end
		if not m_simpleTV.Control.CurrentAddress:match('^https?://mediabay%.tv/tv/%d+') then return end
	local inAdr = m_simpleTV.Control.CurrentAddress
	if m_simpleTV.Control.MainMode == 0 then
		m_simpleTV.Interface.SetBackground({BackColor = 0, PictFileName = '', TypeBackColor = 0, UseLogo = 0, Once = 1})
	end
	m_simpleTV.Control.ChangeAddress = 'Yes'
	m_simpleTV.Control.CurrentAddress = 'erorr'
	local ua = 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML,like Gecko) Chrome/79.0.2785.143 Safari/537.36'
	local extOpt = '$OPT:http-referrer=' .. inAdr .. '$OPT:http-user-agent=' .. ua
	local session = m_simpleTV.Http.New(ua)
		if not session then return end
	m_simpleTV.Http.SetTimeout(session, 12000)
	local rc, answer = m_simpleTV.Http.Request(session, {url = decode64('aHR0cDovL2FwaW02Lm1lZGlhYmF5LnR2L3YyL2NoYW5uZWxzL3RocmVhZC8=') .. inAdr:match('tv/(%d+)')})
		if rc ~= 200 then
			m_simpleTV.Http.Close(session)
		 return
		end
	require 'json'
	local tab = json.decode(answer:gsub('%[%]', '"nil"'))
		if not tab or not tab.data or not tab.data[1].threadAddress then return end
	local retAdr = tab.data[1].threadAddress
	rc, answer = m_simpleTV.Http.Request(session, {url = retAdr})
	m_simpleTV.Http.Close(session)
		if rc ~= 200 then return end
	local base = retAdr:match('.+/')
	local i, t, name, adr = 1, {}
		for w in answer:gmatch('EXT%-X%-STREAM%-INF(.-%.m3u8.-)\n') do
			adr = w:match('\n(.+)')
				if not adr then break end
			name = w:match('RESOLUTION=%d+x(%d+)')
			if name then
				if not adr:match('^http') then
					adr = base .. adr:gsub('%.%./', ''):gsub('^/', '')
				end
				t[i] = {}
				t[i].Id = tonumber(name)
				t[i].Name = name .. 'p'
				t[i].Address = adr .. extOpt
				i = i + 1
			end
		end
		if i == 1 then
			m_simpleTV.Control.CurrentAddress = retAdr .. extOpt
		 return
		end
	table.sort(t, function(a, b) return a.Id < b.Id end)
	local lastQuality = tonumber(m_simpleTV.Config.GetValue('mediabay_qlty') or 5000)
	local index = #t
	if #t > 1 then
		t[#t + 1] = {}
		t[#t].Id = 5000
		t[#t].Name = '▫ всегда высокое'
		t[#t].Address = t[#t - 1].Address
		t[#t + 1] = {}
		t[#t].Id = 10000
		t[#t].Name = '▫ адаптивное'
		t[#t].Address = retAdr .. extOpt
		index = #t
			for i = 1, #t do
				if t[i].Id >= lastQuality then
					index = i
				 break
				end
			end
		if index > 1 then
			if t[index].Id > lastQuality then
				index = index - 1
			end
		end
		if m_simpleTV.Control.MainMode == 0 then
			t.ExtButton1 = {ButtonEnable = true, ButtonName = '✕', ButtonScript = 'm_simpleTV.Control.ExecuteAction(37)'}
			t.ExtParams = {LuaOnOkFunName = 'mediabaySaveQuality'}
			m_simpleTV.OSD.ShowSelect_UTF8('⚙ Качество', index - 1, t, 5000, 32 + 64 + 128)
		end
	end
	m_simpleTV.Control.CurrentAddress = t[index].Address
	function mediabaySaveQuality(obj, id)
		m_simpleTV.Config.SetValue('mediabay_qlty', id)
	end
-- debug_in_file(t[index].Address .. '\n')