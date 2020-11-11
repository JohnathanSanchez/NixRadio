ffi.cdef[[
    void* LoadLibraryA(const char* lpLibFileName);
    void* GetProcAddress(void* hModule, const char* lpProcName);
]]

local bass_dll =  ffi.C.LoadLibraryA("bass.dll")

local BASS_Init = ffi.cast("int(__stdcall*)(int, unsigned long, unsigned long, void*, void*)", ffi.C.GetProcAddress(bass_dll, "BASS_Init"))
local BASS_StreamCreateURL = ffi.cast("unsigned long(__stdcall*)(const char *, unsigned long, unsigned long, void*, void*)", ffi.C.GetProcAddress(bass_dll, "BASS_StreamCreateURL"))
local BASS_ChannelPlay = ffi.cast("int( __stdcall*)(unsigned long, int)", ffi.C.GetProcAddress(bass_dll, "BASS_ChannelPlay"))
local BASS_ChannelStop = ffi.cast("int(__stdcall*)(unsigned long)", ffi.C.GetProcAddress(bass_dll, "BASS_ChannelStop"))
local BASS_ChannelSetAttribute = ffi.cast("int(__stdcall*)( unsigned long, unsigned long, float )", ffi.C.GetProcAddress(bass_dll, "BASS_ChannelSetAttribute"))
local BASS_Free = ffi.cast("int(__stdcall*)()", ffi.C.GetProcAddress(bass_dll, "BASS_Free"))

local BASS_DEVICE_3D = 4
local BASS_ATTRIB_VOL = 2

local stations =
{
    "https://streams.bigfm.de/bigfm-usrap-128-mp3",
    "https://streams.bigfm.de/bigfm-oldschool-128-mp3",
    "https://streams.bigfm.de/bigfm-hiphop-128-mp3",
    "http://us3.internet-radio.com:8313/",
    "http://45.79.6.42:2410/listen.pls?sid=1",
    "http://uk1.internet-radio.com:8011/",
    "http://us5.internet-radio.com:8279/",
    "http://uk7.internet-radio.com:8040/",
}

local names =
{
    "none", "usrap", "old school rap", "hiphop",
    "kcvr rap", "westcoast", "rock",
    "classic rock", "90s"
}

ui.add_combo("station", "radio_station", names, 0)
ui.add_checkbox("play", "radio_play", false)
ui.add_slider_float("volume", "radio_volume", 0.0, 1.0, 0.1)

local old_station = ui.get_int("radio_station")
local old_can_play = old_station > 0 and ui.get_bool("radio_play")
local stream, playing = 0, false

BASS_Init(-1, 44100, BASS_DEVICE_3D, nil, nil)

client.register_callback("frame_stage_notify", function(stage)
    if stage == 5 then
        local radio_station = ui.get_int("radio_station")
        local radio_play = ui.get_bool("radio_play")
        local can_play = radio_station > 0 and radio_play
        local switch = old_station ~= radio_station and can_play

        if switch or (can_play and not playing) then
            if stream ~= 0 then
                BASS_ChannelStop(stream)
            end

            stream = BASS_StreamCreateURL(stations[radio_station], 0, 0, nil, nil)
            BASS_ChannelPlay(stream, 0)
            playing = true
        end

        if not can_play and stream ~= 0 and playing then
            BASS_ChannelStop(stream)
            playing = false
        end

        if playing and stream ~= 0 then
            BASS_ChannelSetAttribute(stream, BASS_ATTRIB_VOL, ui.get_float("radio_volume"))
        end

        old_station = radio_station
    end
end
)

client.register_callback("unload", function()
    BASS_ChannelStop(stream)
    BASS_Free();
end
)