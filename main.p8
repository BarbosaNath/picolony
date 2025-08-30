pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- main --

-- init --
function _init()
	poke(0x5f2d, 1)
	generate_world()
	people = {}
	person_id = 1
	
	mouse_x=0
	mouse_y=0
	
	selected = nil
	
	for i=0, 10 do
		add(people, generate_person())
	end
end


-- update --
function _update()
	for person in all(people) do
		act_person(person)
	end
	
	mouse_x=stat(32)
	mouse_y=stat(33)
	
	select_entity()
end


-- draw --
function _draw()
 cls()
--	debug_person(p)

	map(0,0,0,0,16,16)
	for p in all(people) do
		spr(p.sp, p.x, p.y)
	end
	
	if selected~=nil then
		person_info(selected)
	end
	
	draw_selection()
	draw_cursor()
end








-->8
-- person --

-- create new person --
function new_person(
	name,x, y
)
	person_id += 1
	return {
		id=person_id,
		name=name,
		x=x,
		y=y,
		target={
			timer=-1,
			x=x,
			y=y,
			block=nil,
		},
		action='idle',
		nacts={}, --next_actions
		lacts={}, --last_actions
		sp=1,
		variant=1,
		inventory={},
		
		humor={
			happiness=5,
			sadness=0,
			hatred=0,
			love=0,
			boredon=0,
		},
		
		humor_text='neutral',
		humor_color=6,
		
		relations={}
	}
end


-- idle --
function idle(p)
	if p.target.timer == -1 then
		p.target.timer = flr(rnd(40))
	end
	
	p.target.timer -= 1

	if p.target.timer == 0 then
		add(p.lacts, 'idle')
		p.target.timer = -1
		p.action = 'random_action'
	end
end


-- move person --
function move_person(p)
	if p.target.x == p.x
	and p.target.y == p.y then
		if is_empty(p.nacts)	then
			add(p.lacts, 'move')
			p.action = 'idle'
		else
			p.action =	pop_left(p.nacts)
		end
		
		p.sp = p.variant
		return
	end

	p.sp = ((p.sp) % 2) + p.variant

	if p.target.x != p.x then
		p.x += p.target.x > p.x and 1 or -1
	end
	
	if p.target.y != p.y then
		p.y += p.target.y > p.y and 1 or -1
	end
end

-- select random action --
function select_random_action(p)	
	p.action = rnd({
		'idle',
		'move',
		'random_move',
	})
end


-- select random place to move --
function select_random_move(p)
	p.target.x=flr(rnd(128))
	p.target.y=flr(rnd(128))
	p.action = 'move'
end


action = {
	idle=idle,
	move=move_person,
	random_action=select_random_action,
	random_move=select_random_move,
}	

-- act acording to action --
function act_person(p)
	action[p.action](p)
	check_humor(p)
end


function check_boredon(p)
	if #p.lacts >= 5 then
		local counter = 0
		
		for i=#p.lacts-5,#p.lacts do
			if p.lacts[i] == 'idle'
			or p.lacts[i] == 'move'
			then
				counter += 1
			end
		end
		
		if counter == 5 then
			deli(p.lacts, 1)
			p.humor.boredon+=p.humor.boredon == 10 and 0 or 1
		end
	end
end


function check_humor(p)
	check_boredon(p)
end



-- render person information --
function person_info(p)
	rectfill(0,86,127,127,0)
	rect(0,86,127,127,7)

	local x = 3
	local y = 89

	function println(t,c)
		print(t,x,y,c)
		y+=7
	end

	println(p.name,7)
	println(p.action,5)
	
	x=63
	y=89
	
	println('happiness: '..p.humor.happiness,10)
	println('sadness: '..p.humor.sadness,13)
	println('hatred: '..p.humor.hatred,8)
	println('love: '..p.humor.love,14)
	println('boredon: '..p.humor.boredon,6)
		
--			happiness=5,
--			sadness=0,
--			hatred=0,
--			love=0,
--			boredon=0,
end


-- debuging functions --
function debug_person(p)
	print(p.name)
	print(p.action)
	print('x: '..p.x..' y: '..p.y)
	print(dump(p.target))
	print('next: '..dump(p.nacts))
	print(p.sp)
end


-- generate person --
function generate_person()
	local person = new_person(
		rnd(
			{
				'alex', 'breno', 'claudio',
				'doug', 'eliza', 'francis',
				'guilheme', 'hilda', 'igor',
				'juniper', 'kai', 'lucas',
				'matheus', 'natalia', 
				'olivia', 'penelope', 
				'quentin',	'roger', 'silvia',
				'tulio', 'ursola',
				'vitoria', 'willian',
				'xavier','yasmin','zuko' 
			}
		),
		flr(rnd(127)),
		flr(rnd(127))
	)
	person.sp = rnd({1,3})
	person.variant = person.sp
	
	return person
end
-->8
-- util --

function pop_left(t)
	local value = t[1]
	
	deli(t, 1)
	
	return value
end

function is_empty(t)
	return #t == 0
end

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s..k..': ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end



-->8
-- world --

-- code by jolly uid=26356 --
terrain = {}
size = 100

-- make random numbered list
function create_list()
	for y=0,size do
	 terrain[y] = {} 
	for x=0,size do
		terrain[y][x] = flr(rnd(16)) + .5
	 
	 if flr(rnd(200)) == 1 then
	 terrain[y][x] = 100
	 end
		
		end
	end
end


--noise using averages
function noise(terrain,times)
	times = times or 1
	
	for i=1,times do
	for y=1,size-1 do
	for x=1,size-1 do
		terrain[y][x] = 
		flr((terrain[y-1][x-1]
		+terrain[y-1][x]
		+terrain[y-1][x+1]
		+terrain[y][x-1]
		+terrain[y][x+1]
		+terrain[y+1][x-1]
		+terrain[y+1][x]
		+terrain[y+1][x+1]) / 8)
	end
	end
	end
end
-- end of code by jolly --

function generate_world()
	create_list()
	noise(terrain, 3)

	map_noise = {
		36, 36, 36, 36,
		32, 32, 20, 20,
		20, 20, 20, 20,
		20, 20, 20, 20,
	}

 -- set basic terrain
 for x=0, size-10 do
	 for y=0, size-10 do
	 	mset(x,y,map_noise[terrain[y+10][x+10]])
	 end 
 end
 
 -- set rocks
 for i=1, 10 do
 	local x = flr(rnd(16))
 	local y = flr(rnd(16))
 	if mget(x,y) == 32 then
 		mset(x,y,48)
 	end
 end
 
 -- set big rocks
 for i=1, 5 do
 	local x = flr(rnd(16))
 	local y = flr(rnd(16))
 	if mget(x,y) == 32 then
 		mset(x,y,49)
 	end
 end
 
 -- set trees
 for i=1, 5 do
 	local x = flr(rnd(16))
 	local y = flr(rnd(16))
 	if mget(x,y) == 32 then
 		mset(x,y,33)
 	end
 end
end
-->8
-- interactions --

function select_entity()
	if stat(34) == 1 then
		reset_selected=true
		for p in all(people) do 
			if (
				mouse_x <= p.x+8 and
				mouse_x >= p.x and
				mouse_y <= p.y+8 and
				mouse_y >= p.y
			) then
				selected=p
				reset_selected=false
				break
			end
		end
		
		if reset_selected then
			selected=nil
		end
	end
end

selection_frame = 0
selection_frame_counter=0
function draw_selection()
	if selected ~= nil then
	 spr(selection_frame+54,selected.x,selected.y)
	end
	
	if selection_frame_counter == 0 then
		selection_frame=(selection_frame+1)%10
	end
	selection_frame_counter=(selection_frame_counter+1)%3
end


function draw_cursor()
	spr(15, mouse_x, mouse_y)
end
__gfx__
00000000004444000044440000555500005555000000000000000000000000000000000000000000000000000000000077000077000000000000000001000000
00000000004f5ff0004f5ff000541440005414400000000000000000000000000000000000000000000000000000000070000007000000000000000017100000
00700700004fff00004fff00005444000054440000000000000ff000000ff0000000000000000000000000000000000070000007000000000000000017710000
00077000000cc000000cc000000cc000000cc00000000000000cc000000cc0000000000000000000000000000000000070000007000000000000000017771000
00077000000cc000000cc000000cc000000cc00000000000000dd000000dd0000000000000000000000000000000000070000007000000000000000017777100
00700700000c1000000c1000000c1000000c100000000000000dd00000dd0d000000000000000000000000000000000070000007000000000000000017711000
00000000000110000001010000011000000101000000000000000000000000000000000000000000000000000000000070000007000000000000000001171000
00000000000110000110001000011000011000100000000000000000000000000000000000000000000000000000000077000077000000000000000000000000
dddddddddd6666dddd6666dddddddddd666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddd6666dddd6666dddddddddd666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666dd6666dddd666666dd6666dd666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666dd6666dddd666666dd6666dd666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666dd6666dddd666666dd6666dd666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666dd6666dddd666666dd6666dd666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddd6666dddddddddddddddddd666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddd6666dddddddddddddddddd666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbb3bbb54bb3b0000000000000000cccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbb34444bb00444400003333001cccccc10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb3bbbbb449944b04499440033b3b30c1cccc1c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb3bbbbbb49ff94b049ff94003b3b330cccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbb449ff94b049ff940033b3b30cccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbb554994440449944003b3b330ccc11ccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbb33444455004444003b3b3b33cc1cc1cc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbb3bbbb35533b0000000033b3b3b3cccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbb3bbbbbbb3b000000333b3b3b33000000000000000077000077dd0000dd0d0000d000000000000000000000000076000067770000777700007777000077
bb67bbbbbbbbbbbb003333b3b3b3b3b3333330000000000070000007d760067dd770077d0770077007700770077007706dd00dd67d0000d77000000770000007
bbd6bbbbbb6677bb033b3b3b3b3b3b3b3b3b3300000000000000000006000060070000700700007007000070070000700d0000d0000000000000000000000000
b3bbbbbbb66667bb03b3b3b3b3b3b3b3b3b3b3300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb3bb776bdd6666b033b3b3b3b3b3b3b3b3b3b300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbb6ddbddddddb03b3b3b3b3b3b3b3b3b3b330000000000000000006000060070000700700007007000070070000700d0000d0000000000000000000000000
77bbbbbbbbbbbbbb0033333b3b3b3b333b3b3b300000000070000007d760067dd770077d0770077007700770077007706dd00dd67d0000d77000000770000007
6dbbb3bbbbbbb3bb0000003333b3b33333b3b3300000000077000077dd0000dd0d0000d000000000000000000000000076000067770000777700007777000077
__gff__
0001010101000000000000000000000084848400000000000000000000000000028288080000000000000000000000000282080808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
