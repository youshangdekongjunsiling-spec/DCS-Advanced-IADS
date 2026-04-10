env.info("--- SKYNET VERSION: 3.3.0 | BUILD TIME: 29.12.2023 2311Z ---")
do
--this file contains the required units per sam type
samTypesDB = {	
	['S-200'] = {
        ['type'] = 'complex',
        ['searchRadar'] = {
            ['RLS_19J6'] = {
                ['name'] = {
                    ['NATO'] = 'Tin Shield',
                },
			}, 
			['p-19 s-125 sr'] = {
				['name'] = {
					['NATO'] = 'Flat Face',
				},
			},	
		},
        ['EWR P-37 BAR LOCK'] = {
            ['Name'] = {
              ['NATO'] = "Bar lock",
            },   
        },
        ['trackingRadar'] = {
            ['RPC_5N62V'] = {
            },
        },
        ['launchers'] = {
            ['S-200_Launcher'] = {
            },
        },
        ['name'] = {
            ['NATO'] = 'SA-5 Gammon',
        },
        ['harm_detection_chance'] = 60
    },
	['S-300'] = {
		['type'] = 'complex',
		['searchRadar'] = {
			['S-300PS 40B6MD sr'] = {
				['name'] = {
					['NATO'] = 'Clam Shell',
				},
			},
			['S-300PS 64H6E sr'] = {
				['name'] = {
					['NATO'] = 'Big Bird',
				},
			},
			['S-300PS 40B6MD sr_19J6'] = {
				['name'] = {
					['NATO'] = 'Tin Shield',
				},
			}
		},
		['trackingRadar'] = {
			['S-300PS 40B6M tr'] = {
			},	
			['S-300PS 5H63C 30H6_tr'] = {
			},
		},
		['launchers'] = {
			['S-300PS 5P85D ln'] = {
			},
			['S-300PS 5P85C ln'] = {
			},
		},
		['misc'] = {
			['S-300PS 54K6 cp'] = {
				['required'] = true,
			},
		},
		['name'] = {
			['NATO'] = 'SA-10 Grumble',
		},
		['harm_detection_chance'] = 90,
		['can_engage_harm'] = true
	},
	['Buk'] = {
		['type'] = 'complex',
		['searchRadarOptional'] = true,
		['searchRadar'] = {
			['SA-11 Buk SR 9S18M1'] = {
				['name'] = {
					['NATO'] = 'Snow Drift',
				},
			},
		},
		['launchers'] = {
			['SA-11 Buk LN 9A310M1'] = {
			},
		},
		['misc'] = {
			['SA-11 Buk CC 9S470M1'] = {
				['required'] = true,
			},
		},
		['name'] = {
			['NATO'] = 'SA-11 Gadfly',
		},
		['harm_detection_chance'] = 70
	},
	['S-125'] = {
		['type'] = 'complex',
		['searchRadar'] = {
			['p-19 s-125 sr'] = {
				['name'] = {
					['NATO'] = 'Flat Face',
				},
			},	
		},
		['trackingRadar'] = {
			['snr s-125 tr'] = {
			},
		},
		['launchers'] = {
			['5p73 s-125 ln'] = {
			},
		},
		['name'] = {
			['NATO'] = 'SA-3 Goa',
		},
		['harm_detection_chance'] = 30
	},
    ['S-75'] = {
		['type'] = 'complex',
		['searchRadar'] = {
			['p-19 s-125 sr'] = {
				['name'] = {
					['NATO'] = 'Flat Face',
				},
			},
		},
		['trackingRadar'] = {
			['SNR_75V'] = {
			},
		},
		['launchers'] = {
			['S_75M_Volhov'] = {
			},
		},
		['name'] = {
			['NATO'] = 'SA-2 Guideline',
		},
		['harm_detection_chance'] = 30
	},
	['Kub'] = {
		['type'] = 'complex',
		['searchRadar'] = {
			['Kub 1S91 str'] = {
				['name'] = {
					['NATO'] = 'Straight Flush',
				},
			},
		},
		['launchers'] = {
			['Kub 2P25 ln'] = {
			},
		},
		['name'] = {
			['NATO'] = 'SA-6 Gainful',
		},
		['harm_detection_chance'] = 40
	},
	['Patriot'] = {
		['type'] = 'complex',
		['searchRadar'] = {
			['Patriot str'] = {
				['name'] = {
					['NATO'] = 'Patriot str',
				},
			},
		},
		['launchers'] = {
			['Patriot ln'] = {
			},
		},
		['misc'] = {
			['Patriot cp'] = {
				['required'] = false,
			},
			['Patriot EPP']  = {
				['required'] = false,
			},
			['Patriot ECS']  = {
				['required'] = true,
			},
			['Patriot AMG']  = {
				['required'] = false,
			},
		},
		['name'] = {
			['NATO'] = 'Patriot',
		},
		['harm_detection_chance'] = 90,
		['can_engage_harm'] = true
	},
	['Hawk'] = {
		['type'] = 'complex',
		['searchRadar'] = {
			['Hawk sr'] = {
				['name'] = {
					['NATO'] = 'Hawk str',
				},
			},
		},
		['trackingRadar'] = {
			['Hawk tr'] = {
			},
		},
		['launchers'] = {
			['Hawk ln'] = {
			},
		},

		['name'] = {
			['NATO'] = 'Hawk',
		},
		['harm_detection_chance'] = 40

	},	
	['Roland ADS'] = {
		['type'] = 'complex',
		['searchRadar'] = {
			['Roland Radar'] = {
				['name'] = {
					['NATO'] = 'Roland EWR',
				},
			},
		},
		['launchers'] = {
			['Roland ADS'] = {
			},
		},
		['name'] = {
			['NATO'] = 'Roland ADS',
		},
		['harm_detection_chance'] = 60
	},	
	['NASAMS'] = {
		['type'] = 'complex',
		['searchRadar'] = {
			['NASAMS_Radar_MPQ64F1'] = {
			},
		},
		['launchers'] = {
			['NASAMS_LN_B'] = {		
			},
			['NASAMS_LN_C'] = {		
			},
		},
		
		['name'] = {
			['NATO'] = 'NASAMS',
		},
		['misc'] = {
			['NASAMS_Command_Post'] = {
				['required'] = false,
			},
		},
		['can_engage_harm'] = true,
		['harm_detection_chance'] = 90
	},	
	['2S6 Tunguska'] = {
		['type'] = 'single',
		['searchRadar'] = {
			['2S6 Tunguska'] = {
			},
		},
		['launchers'] = {
			['2S6 Tunguska'] = {
			},
		},
		['name'] = {
			['NATO'] = 'SA-19 Grison',
		},
	},		
	['Osa'] = {
		['type'] = 'single',
		['searchRadar'] = {
			['Osa 9A33 ln'] = {
			},
		},
		['launchers'] = {
			['Osa 9A33 ln'] = {
			
			},
		},
		['name'] = {
			['NATO'] = 'SA-8 Gecko',
		},
		['harm_detection_chance'] = 20
	},	
	['Strela-10M3'] = {
		['type'] = 'single',
		['searchRadar'] = {
			['Strela-10M3'] = {
				['trackingRadar'] = true,
			},
		},
		['launchers'] = {
			['Strela-10M3'] = {
			},
		},
		['name'] = {
			['NATO'] = 'SA-13 Gopher',
		},
	},	
	['Strela-1 9P31'] = {
		['type'] = 'single',
		['searchRadar'] = {
			['Strela-1 9P31'] = {
			},
		},
		['launchers'] = {
			['Strela-1 9P31'] = {
			},
		},
		['name'] = {
			['NATO'] = 'SA-9 Gaskin',
		},
		['harm_detection_chance'] = 20
	},
	['Tor'] = {
		['type'] = 'single',
		['searchRadar'] = {
			['Tor 9A331'] = {
			},
		},
		['launchers'] = {
			['Tor 9A331'] = {
			},
		},
		['name'] = {
			['NATO'] = 'SA-15 Gauntlet',
		},
		['harm_detection_chance'] = 90,
		['can_engage_harm'] = true
		
	},
	['Gepard'] = {
		['type'] = 'single',
		['searchRadar'] = {
			['Gepard'] = {
			},
		},
		['launchers'] = {
			['Gepard'] = {
			},
		},
		['name'] = {
			['NATO'] = 'Gepard',
		},
		['harm_detection_chance'] = 10
	},		
    ['Rapier'] = {
        ['searchRadar'] = {
            ['rapier_fsa_blindfire_radar'] = {
            },
        },
        ['launchers'] = {
        	['rapier_fsa_launcher'] = {
				['trackingRadar'] = true,
			},
        },
        ['misc'] = {
            ['rapier_fsa_optical_tracker_unit'] = {
                ['required'] = true,
            },
        },
        ['name'] = {
			['NATO'] = 'Rapier',
		},
		['harm_detection_chance'] = 10
    },	
	['ZSU-23-4 Shilka'] = {
		['type'] = 'single',
		['searchRadar'] = {
			['ZSU-23-4 Shilka'] = {
			},
		},
		['launchers'] = {
			['ZSU-23-4 Shilka'] = {
			},
		},
		['name'] = {
			['NATO'] = 'Zues',
		},
		['harm_detection_chance'] = 10
	},
	['HQ-7'] = {
		['searchRadar'] = {
			['HQ-7_STR_SP'] = {
				['name'] = {
					['NATO'] = 'CSA-4',
				},
			},
		},
		['launchers'] = {
			['HQ-7_LN_SP'] = {
			},
		},
		['name'] = {
			['NATO'] = 'CSA-4',
		},
		['harm_detection_chance'] = 30
	},	
	['Phalanx'] = {
		['type'] = 'single',
		['searchRadar'] = {
			['HEMTT_C-RAM_Phalanx'] = {
			},
		},
		['launchers'] = {
			['HEMTT_C-RAM_Phalanx'] = {
			},
		},
		['name'] = {
			['NATO'] = 'Phalanx',
		},
		['harm_detection_chance'] = 10
	},	
-- Start of RED EW radars:	
	['1L13 EWR'] = {
		['type'] = 'ewr',
		['searchRadar'] = {
			['1L13 EWR'] = {
				['name'] = {
					['NATO'] = 'Box Spring',
				},
			},
		},
		['harm_detection_chance'] = 60
	},
	['55G6 EWR'] = {
		['type'] = 'ewr',
		['searchRadar'] = {
			['55G6 EWR'] = {
				['name'] = {
					['NATO'] = 'Tall Rack',
				},
			},
		},
		['harm_detection_chance'] = 60
	},
	['Dog Ear'] = {
		['type'] = 'ewr',
		['searchRadar'] = {
			['Dog Ear radar'] = {
				['name'] = {
					['NATO'] = 'Dog Ear',
				},
			},
		},
		['harm_detection_chance'] = 20
	},
-- Start of BLUE EW radars:
	['FPS-117 Dome'] = {
		['type'] = 'ewr',
		['searchRadar'] = {
			['FPS-117 Dome'] = {
				['name'] = {
					['NATO'] = 'FPS-117 Dome',
				},
			},
		},
		['harm_detection_chance'] = 80
	},
	['FPS-117'] = {
		['type'] = 'ewr',
		['searchRadar'] = {
			['FPS-117'] = {
				['name'] = {
					['NATO'] = 'FPS-117',
				},
			},
		},
		['harm_detection_chance'] = 80
	}
}
end
do
-- this file contains the definitions for the HightDigitSAMSs: https://github.com/Auranis/HighDigitSAMs

--EW radars used in multiple SAM systems:

s300PMU164N6Esr = {
	['name'] = {
		['NATO'] = 'Big Bird',
	},
}

s300PMU140B6MDsr = {
	['name'] = {
		['NATO'] = 'Clam Shell',
	},
}

--[[ units in SA-10 group Gargoyle:
2020-12-10 18:27:27.050 INFO    SCRIPTING: S-300PMU1 54K6 cp
2020-12-10 18:27:27.050 INFO    SCRIPTING: S-300PMU1 5P85CE ln
2020-12-10 18:27:27.050 INFO    SCRIPTING: S-300PMU1 5P85DE ln
2020-12-10 18:27:27.050 INFO    SCRIPTING: S-300PMU1 40B6MD sr
2020-12-10 18:27:27.050 INFO    SCRIPTING: S-300PMU1 64N6E sr
2020-12-10 18:27:27.050 INFO    SCRIPTING: S-300PMU1 40B6M tr
2020-12-10 18:27:27.050 INFO    SCRIPTING: S-300PMU1 30N6E tr
--]]
samTypesDB['S-300PMU1'] = {
	['type'] = 'complex',
	['searchRadar'] = {
		['S-300PMU1 40B6MD sr'] = s300PMU140B6MDsr,
		['S-300PMU1 64N6E sr'] = s300PMU164N6Esr,
		
		['S-300PS 40B6MD sr'] = {
			['name'] = {
				['NATO'] = '',
			},
		},
		['S-300PS 64H6E sr'] = {
			['name'] = {
				['NATO'] = '',
			},
		},
	},
	['trackingRadar'] = {
		['S-300PMU1 40B6M tr'] = {
			['name'] = {
				['NATO'] = 'Grave Stone',
			},
		},
		['S-300PMU1 30N6E tr'] = {
			['name'] = {
				['NATO'] = 'Flap Lid',
			},

		},
		['S-300PS 40B6M tr'] = {
			['name'] = {
				['NATO'] = '',
			},
		},
	},
	['misc'] = {
		['S-300PMU1 54K6 cp'] = {
			['required'] = true,
		},
	},
	['launchers'] = {
		['S-300PMU1 5P85CE ln'] = {
		},
		['S-300PMU1 5P85DE ln'] = {
		},
	},
	['name']  = {
		['NATO'] = 'SA-20A Gargoyle'
	},
	['harm_detection_chance'] = 90,
	['can_engage_harm'] = true
}	

--[[ Units in the SA-23 Group:
2020-12-11 16:40:52.072 INFO    SCRIPTING: S-300VM 9A82ME ln
2020-12-11 16:40:52.072 INFO    SCRIPTING: S-300VM 9A83ME ln
2020-12-11 16:40:52.072 INFO    SCRIPTING: S-300VM 9S15M2 sr
2020-12-11 16:40:52.072 INFO    SCRIPTING: S-300VM 9S19M2 sr
2020-12-11 16:40:52.072 INFO    SCRIPTING: S-300VM 9S32ME tr
2020-12-11 16:40:52.072 INFO    SCRIPTING: S-300VM 9S457ME cp

]]--
samTypesDB['S-300VM'] = {
	['type'] = 'complex',
	['searchRadar'] = {
		['S-300VM 9S15M2 sr'] = {
			['name'] = {
				['NATO'] = 'Bill Board-C',
			},
		},
		['S-300VM 9S19M2 sr'] = {
			['name'] = {
				['NATO'] = 'High Screen-B',
			},
		},
	},
	['trackingRadar'] = {
		['S-300VM 9S32ME tr'] = {
		},
	},
	['misc'] = {
		['S-300VM 9S457ME cp'] = {
			['required'] = true,
		},
	},
	['launchers'] = {
		['S-300VM 9A82ME ln'] = {
		},
		['S-300VM 9A83ME ln'] = {
		},
	},
	['name']  = {
		['NATO'] = 'SA-23 Antey-2500'
	},
	['harm_detection_chance'] = 90,
	['can_engage_harm'] = true
}	

--[[ Units in the SA-10B Group:
2021-01-01 20:39:14.413 INFO    SCRIPTING: S-300PS SA-10B 40B6MD MAST sr
2021-01-01 20:39:14.413 INFO    SCRIPTING: S-300PS SA-10B 54K6 cp
2021-01-01 20:39:14.413 INFO    SCRIPTING: S-300PS 5P85SE_mod ln
2021-01-01 20:39:14.413 INFO    SCRIPTING: S-300PS 5P85SU_mod ln
2021-01-01 20:39:14.413 INFO    SCRIPTING: S-300PS 64H6E TRAILER sr
2021-01-01 20:39:14.413 INFO    SCRIPTING: S-300PS 30N6 TRAILER tr
2021-01-01 20:39:14.413 INFO    SCRIPTING: S-300PS SA-10B 40B6M MAST tr
--]]
samTypesDB['S-300PS'] = {
	['type'] = 'complex',
	['searchRadar'] = {
		['S-300PS SA-10B 40B6MD MAST sr'] = {
			['name'] = {
				['NATO'] = 'Clam Shell',
			},
		},
		['S-300PS 64H6E TRAILER sr'] = {
		},
	},
	['trackingRadar'] = {
		['S-300PS 30N6 TRAILER tr'] = {
		},
		['S-300PS SA-10B 40B6M MAST tr'] = {
		},
		['S-300PS 40B6M tr'] = {
		},
		['S-300PMU1 40B6M tr'] = {
		},	
		['S-300PMU1 30N6E tr'] = {
		},		
	},
	['misc'] = {
		['S-300PS SA-10B 54K6 cp'] = {
			['required'] = true,
		},
	},
	['launchers'] = {
		['S-300PS 5P85SE_mod ln'] = {
		},
		['S-300PS 5P85SU_mod ln'] = {
		},
	},
	['name']  = {
		['NATO'] = 'SA-10B Grumble'
	},
	['harm_detection_chance'] = 90,
	['can_engage_harm'] = true
}

--[[ Extra launchers for the in game SA-10C and HighDigitSAMs SA-10B, SA-20B
2021-01-01 21:04:19.908 INFO    SCRIPTING: S-300PS 5P85DE ln
2021-01-01 21:04:19.908 INFO    SCRIPTING: S-300PS 5P85CE ln
--]]

local s300launchers = samTypesDB['S-300']['launchers']
s300launchers['S-300PS 5P85DE ln'] = {}
s300launchers['S-300PS 5P85CE ln'] = {}

local s300launchers = samTypesDB['S-300PS']['launchers']
s300launchers['S-300PS 5P85DE ln'] = {}
s300launchers['S-300PS 5P85CE ln'] = {}

local s300launchers = samTypesDB['S-300PMU1']['launchers']
s300launchers['S-300PS 5P85DE ln'] = {}
s300launchers['S-300PS 5P85CE ln'] = {}

--[[
New launcher for the SA-11 complex, will identify as SA-17
SA-17 Buk M1-2 LN 9A310M1-2
 --]]
samTypesDB['Buk-M2'] = {
	['type'] = 'complex',
	['searchRadar'] = {
		['SA-11 Buk SR 9S18M1'] = {
			['name'] = {
				['NATO'] = 'Snow Drift',
			},
		},
	},
	['launchers'] = {
		['SA-17 Buk M1-2 LN 9A310M1-2'] = {
		},
	},
	['misc'] = {
		['SA-11 Buk CC 9S470M1'] = {
			['required'] = true,
		},
	},
	['name'] = {
		['NATO'] = 'SA-17 Grizzly',
	},
	['harm_detection_chance'] = 90
}

--[[
New launcher for the SA-2 complex: S_75M_Volhov_V759
--]]
local s75launchers = samTypesDB['S-75']['launchers']
s75launchers['S_75M_Volhov_V759'] = {}

--[[
New launcher for the SA-3 complex:
--]]
local s125launchers = samTypesDB['S-125']['launchers']
s125launchers['5p73 V-601P ln'] = {}

--[[
New launcher for the SA-2 complex: HQ_2_Guideline_LN
--]]
local s125launchers = samTypesDB['S-75']['launchers']
s125launchers['HQ_2_Guideline_LN'] = {}

--[[
SA-12 Gladiator / Giant:
2021-03-19 21:24:22.620 INFO    SCRIPTING: S-300V 9S15 sr
2021-03-19 21:24:22.620 INFO    SCRIPTING: S-300V 9S19 sr
2021-03-19 21:24:22.620 INFO    SCRIPTING: S-300V 9S32 tr
2021-03-19 21:24:22.620 INFO    SCRIPTING: S-300V 9S457 cp
2021-03-19 21:24:22.620 INFO    SCRIPTING: S-300V 9A83 ln
2021-03-19 21:24:22.620 INFO    SCRIPTING: S-300V 9A82 ln
--]]
samTypesDB['S-300V'] = {
	['type'] = 'complex',
	['searchRadar'] = {
		['S-300V 9S15 sr'] = {
			['name'] = {
				['NATO'] = 'Bill Board',
			},
		},
		['S-300V 9S19 sr'] = {
			['name'] = {
				['NATO'] = 'High Screen',
			},
		},
	},
	['trackingRadar'] = {
		['S-300V 9S32 tr'] = {
			['NATO'] = 'Grill Pan',
			},
	},
	['misc'] = {
		['S-300V 9S457 cp'] = {
			['required'] = true,
		},
	},
	['launchers'] = {
		['S-300V 9A83 ln'] = {
		},
		['S-300V 9A82 ln'] = {
		},
	},
	['name']  = {
		['NATO'] = 'SA-12 Gladiator/Giant'
	},
	['harm_detection_chance'] = 90,
	['can_engage_harm'] = true
}

--[[
SA-20B Gargoyle B:

2021-03-25 19:15:02.135 INFO    SCRIPTING: S-300PMU2 64H6E2 sr
2021-03-25 19:15:02.135 INFO    SCRIPTING: S-300PMU2 92H6E tr
2021-03-25 19:15:02.135 INFO    SCRIPTING: S-300PMU2 5P85SE2 ln
2021-03-25 19:15:02.135 INFO    SCRIPTING: S-300PMU2 54K6E2 cp
--]]

samTypesDB['S-300PMU2'] = {
	['type'] = 'complex',
	['searchRadar'] = {
		['S-300PMU2 64H6E2 sr'] = {
			['name'] = {
				['NATO'] = '',
			},
		},
		['S-300PMU1 40B6MD sr'] = s300PMU140B6MDsr,
		['S-300PMU1 64N6E sr'] = s300PMU164N6Esr,
	},
	['trackingRadar'] = {
		['S-300PMU2 92H6E tr'] = {
		},
		['S-300PS 40B6M tr'] = {
		},
		['S-300PMU1 40B6M tr'] = {
		},
		['S-300PMU1 30N6E tr'] = {
		},
	},
	['misc'] = {
		['S-300PMU2 54K6E2 cp'] = {
			['required'] = true,
		},
	},
	['launchers'] = {
		['S-300PMU2 5P85SE2 ln'] = {
		},
	},
	['name']  = {
		['NATO'] = 'SA-20B Gargoyle B'
	},
	['harm_detection_chance'] = 90,
	['can_engage_harm'] = true
}

--[[

--]]
end



do

SkynetIADSLogger = {}
SkynetIADSLogger.__index = SkynetIADSLogger

function SkynetIADSLogger:create(iads)
	local logger = {}
	setmetatable(logger, SkynetIADSLogger)
	logger.debugOutput = {}
	logger.debugOutput.IADSStatus = false
	logger.debugOutput.samWentDark = false
	logger.debugOutput.contacts = false
	logger.debugOutput.radarWentLive = false
	logger.debugOutput.jammerProbability = false
	logger.debugOutput.addedEWRadar = false
	logger.debugOutput.addedSAMSite = false
	logger.debugOutput.warnings = true
	logger.debugOutput.harmDefence = false
	logger.debugOutput.samSiteStatusEnvOutput = false
	logger.debugOutput.earlyWarningRadarStatusEnvOutput = false
	logger.debugOutput.commandCenterStatusEnvOutput = false
	logger.iads = iads
	return logger
end

function SkynetIADSLogger:getDebugSettings()
	return self.debugOutput
end

function SkynetIADSLogger:printOutput(output, typeWarning)
	if typeWarning == true and self:getDebugSettings().warnings or typeWarning == nil then
		if typeWarning == true then
			output = "WARNING: "..output
		end
		trigger.action.outText(output, 4)
	end
end

function SkynetIADSLogger:printOutputToLog(output)
	env.info("SKYNET: "..output, 4)
end

local function joinStrings(values, separator)
	if values == nil or #values == 0 then
		return ""
	end
	return table.concat(values, separator or ", ")
end

local function boolFlag(value)
	if value then
		return "Y"
	end
	return "N"
end

local function safeUnitAmmoCount(unit)
	if unit == nil or unit.isExist == nil or unit:isExist() == false then
		return 0
	end
	local okAmmo, ammo = pcall(function()
		return unit:getAmmo()
	end)
	if okAmmo ~= true or ammo == nil then
		return 0
	end
	local count = 0
	for i = 1, #ammo do
		local entry = ammo[i]
		if entry and entry.count and entry.count > 0 then
			count = count + entry.count
		end
	end
	return count
end

function SkynetIADSLogger:getMobilePatrolEntry(abstractRadarElement)
	if SkynetIADSMobilePatrol and SkynetIADSMobilePatrol.getEntryForElement then
		return SkynetIADSMobilePatrol.getEntryForElement(abstractRadarElement)
	end
	return nil
end

function SkynetIADSLogger:getUsableParentEWCount(samSite)
	local parents = samSite:getParentRadars()
	local count = 0
	for i = 1, #parents do
		local parent = parents[i]
		if parent
			and parent:getActAsEW() == true
			and parent:isDestroyed() == false
			and parent:hasWorkingPowerSource()
			and parent:hasActiveConnectionNode()
		then
			count = count + 1
		end
	end
	return count
end

function SkynetIADSLogger:getSAMSiteStateLabel(samSite)
	local patrolEntry = self:getMobilePatrolEntry(samSite)
	if samSite:isDestroyed() then
		return "DESTROYED"
	end
	if patrolEntry and patrolEntry.state == "harm_evading" then
		return "HARM_EVADING"
	end
	if samSite:isDefendingHARM() then
		return "HARM_DEFENCE"
	end
	if patrolEntry and patrolEntry.state == "patrolling" then
		return "PATROLLING"
	end
	if samSite:isActive() then
		if samSite:isJammed() then
			return "COMBAT_JAMMED"
		end
		return "COMBAT"
	end
	if samSite:getAutonomousState() then
		if samSite:getAutonomousBehaviour() == SkynetIADSAbstractRadarElement.AUTONOMOUS_STATE_DARK then
			return "AUTONOMOUS_DARK"
		end
		return "AUTONOMOUS_DCS_AI"
	end
	if samSite:getActAsEW() then
		return "ACTING_AS_EW"
	end
	return "DARK"
end

function SkynetIADSLogger:getSAMSiteWhyText(samSite)
	local patrolEntry = self:getMobilePatrolEntry(samSite)
	local usableParents = self:getUsableParentEWCount(samSite)
	if samSite:isDestroyed() then
		return "Launcher and radar assets are destroyed."
	end
	if patrolEntry and patrolEntry.state == "harm_evading" then
		return "Mobile patrol state is harm_evading; the group is repositioning to evade HARM."
	end
	if samSite:isDefendingHARM() then
		return "The site detected a HARM threat and is executing HARM defence."
	end
	if patrolEntry and patrolEntry.state == "patrolling" then
		return "Mobile patrol state is patrolling; emitters are forced dark until a threat enters the patrol trigger range."
	end
	if samSite:isActive() then
		if samSite.targetsInRange == true then
			return "A target is in range and go-live constraints are satisfied, so the site is active."
		end
		if samSite:getActAsEW() then
			return "The site is active because it is configured to act as EW."
		end
		return "The site is active due to current Skynet/DCS AI state."
	end
	if samSite:isJammed() then
		return "The site is currently jammed and not actively radiating."
	end
	if samSite:hasWorkingPowerSource() == false then
		return "The site has no working power source."
	end
	if samSite:hasActiveConnectionNode() == false then
		return "The site has no active connection node."
	end
	if self.iads:isCommandCenterUsable() == false then
		return "The command center is unavailable."
	end
	if samSite:hasWorkingRadar() == false then
		return "The site has no working radar."
	end
	if samSite:hasRemainingAmmo() == false and samSite:getActAsEW() == false then
		return "The site has no remaining ammunition."
	end
	if samSite:getAutonomousState() then
		if samSite:getAutonomousBehaviour() == SkynetIADSAbstractRadarElement.AUTONOMOUS_STATE_DARK then
			return "The site is autonomous and configured to stay dark."
		end
		return "The site is autonomous and waiting for local DCS AI conditions to trigger."
	end
	if usableParents > 0 then
		return "The site is dark and waiting for a target to enter range or for Skynet to promote it from external EW coverage."
	end
	return "The site is dark because no target is in range and no higher-priority trigger is active."
end

function SkynetIADSLogger:getSAMSiteUnitRoleMap(samSite)
	local roleMap = {}
	local function markUnits(wrappers, roleName)
		for i = 1, #wrappers do
			local wrapper = wrappers[i]
			if wrapper and wrapper.getDCSRepresentation then
				local dcsObject = wrapper:getDCSRepresentation()
				if dcsObject and dcsObject.isExist and dcsObject:isExist() and dcsObject.getName then
					local unitName = dcsObject:getName()
					if roleMap[unitName] == nil then
						roleMap[unitName] = {}
					end
					roleMap[unitName][#roleMap[unitName] + 1] = roleName
				end
			end
		end
	end

	markUnits(samSite:getSearchRadars(), "Search")
	markUnits(samSite:getTrackingRadars(), "Track")
	markUnits(samSite:getLaunchers(), "Launcher")
	markUnits(samSite:getPowerSources(), "Power")
	markUnits(samSite:getConnectionNodes(), "Conn")

	local emitters = samSite:getEmitterRepresentations()
	for i = 1, #emitters do
		local emitter = emitters[i]
		if emitter and emitter.isExist and emitter:isExist() and emitter.getName then
			local emitterName = emitter:getName()
			if roleMap[emitterName] == nil then
				roleMap[emitterName] = {}
			end
			roleMap[emitterName][#roleMap[emitterName] + 1] = "Emitter"
		end
	end

	return roleMap
end

function SkynetIADSLogger:buildDetailedSAMSiteReport(samSite)
	if samSite == nil then
		return "Detailed State | SAM site not found"
	end

	local lines = {}
	local dcsGroup = samSite:getDCSRepresentation()
	local groupName = samSite:getDCSName()
	local patrolEntry = self:getMobilePatrolEntry(samSite)
	local roleMap = self:getSAMSiteUnitRoleMap(samSite)
	local detectedTargets = samSite:getDetectedTargets()
	local reasons = {}

	reasons[#reasons + 1] = "active=" .. boolFlag(samSite:isActive())
	reasons[#reasons + 1] = "targetsInRange=" .. boolFlag(samSite.targetsInRange == true)
	reasons[#reasons + 1] = "autonomous=" .. boolFlag(samSite:getAutonomousState())
	reasons[#reasons + 1] = "power=" .. (samSite:hasWorkingPowerSource() and "OK" or "DOWN")
	reasons[#reasons + 1] = "connection=" .. (samSite:hasActiveConnectionNode() and "OK" or "DOWN")
	reasons[#reasons + 1] = "cmd=" .. (self.iads:isCommandCenterUsable() and "OK" or "DOWN")
	reasons[#reasons + 1] = "radar=" .. (samSite:hasWorkingRadar() and "OK" or "DOWN")
	reasons[#reasons + 1] = "ammo=" .. (samSite:hasRemainingAmmo() and "OK" or "EMPTY")
	reasons[#reasons + 1] = "jammed=" .. boolFlag(samSite:isJammed())
	reasons[#reasons + 1] = "harm=" .. boolFlag(samSite:isDefendingHARM())
	reasons[#reasons + 1] = "actAsEW=" .. boolFlag(samSite:getActAsEW())
	reasons[#reasons + 1] = "parents=" .. tostring(self:getUsableParentEWCount(samSite))
	reasons[#reasons + 1] = "detected=" .. tostring(#detectedTargets)
	reasons[#reasons + 1] = "mif=" .. tostring(samSite:getNumberOfMissilesInFlight())
	if patrolEntry then
		reasons[#reasons + 1] = "mobilePatrol=" .. tostring(patrolEntry.state)
	end

	lines[#lines + 1] = "Detailed State"
	lines[#lines + 1] = "GROUP: " .. groupName .. " | NATO: " .. samSite:getNatoName() .. " | STATE: " .. self:getSAMSiteStateLabel(samSite)
	lines[#lines + 1] = "WHY: " .. self:getSAMSiteWhyText(samSite)
	lines[#lines + 1] = "FLAGS: " .. joinStrings(reasons, " | ")
	if patrolEntry and patrolEntry.lastDeployTrigger then
		local triggerInfo = patrolEntry.lastDeployTrigger
		local ageSeconds = 0
		if triggerInfo.time then
			ageSeconds = math.max(0, timer.getTime() - triggerInfo.time)
		end
		lines[#lines + 1] =
			"LAST DEPLOY: source=" .. tostring(triggerInfo.source)
			.. " | contact=" .. tostring(triggerInfo.contactName)
			.. " | type=" .. tostring(triggerInfo.contactType)
			.. " | distance=" .. tostring(triggerInfo.distanceNm) .. "nm"
			.. " | threatRange=" .. tostring(triggerInfo.threatRangeNm) .. "nm"
			.. " | age=" .. tostring(mist.utils.round(ageSeconds, 1)) .. "s"
	end
	if SkynetIADSSiblingCoordination and SkynetIADSSiblingCoordination.getFamilyForElement then
		local siblingInfo = SkynetIADSSiblingCoordination.getFamilyForElement(samSite)
		if siblingInfo then
			lines[#lines + 1] =
				"SIBLING: family=" .. tostring(siblingInfo.name)
				.. " | mode=" .. tostring(siblingInfo.mode)
				.. " | role=" .. tostring(siblingInfo.role)
				.. " | primary=" .. tostring(siblingInfo.primaryGroupName)
				.. " | preferred=" .. tostring(siblingInfo.preferredPrimaryGroupName)
				.. " | reason=" .. tostring(siblingInfo.reason)
				.. " | passive=" .. tostring(siblingInfo.passiveAction)
		end
	end

	local parentNames = {}
	local parents = samSite:getParentRadars()
	for i = 1, #parents do
		parentNames[#parentNames + 1] = parents[i]:getDCSName()
	end
	if #parentNames > 0 then
		lines[#lines + 1] = "PARENTS: " .. joinStrings(parentNames, ", ")
	end

	local childNames = {}
	local children = samSite:getChildRadars()
	for i = 1, #children do
		childNames[#childNames + 1] = children[i]:getDCSName()
	end
	if #childNames > 0 then
		lines[#lines + 1] = "CHILDREN: " .. joinStrings(childNames, ", ")
	end

	lines[#lines + 1] = "UNITS:"
	if dcsGroup and dcsGroup.isExist and dcsGroup:isExist() then
		local units = dcsGroup:getUnits()
		for i = 1, #units do
			local unit = units[i]
			local unitName = unit:getName()
			local typeName = unit:getTypeName()
			local roles = roleMap[unitName] or { "Other" }
			local sensors = "N"
			local okSensors, sensorData = pcall(function()
				return unit:getSensors()
			end)
			if okSensors and sensorData ~= nil then
				sensors = "Y"
			end
			lines[#lines + 1] = string.format(
				"%d. %s | %s | ALIVE | Roles:%s | Sensors:%s | Ammo:%d",
				i,
				unitName,
				typeName,
				joinStrings(roles, "/"),
				sensors,
				safeUnitAmmoCount(unit)
			)
		end
	else
		lines[#lines + 1] = "GROUP DESTROYED"
	end

	return table.concat(lines, "\n")
end

function SkynetIADSLogger:printEarlyWarningRadarStatus()
	local ewRadars = self.iads:getEarlyWarningRadars()
	self:printOutputToLog("------------------------------------------ EW RADAR STATUS: "..self.iads:getCoalitionString().." -------------------------------")
	for i = 1, #ewRadars do
		local ewRadar = ewRadars[i]
		local numConnectionNodes = #ewRadar:getConnectionNodes()
		local numPowerSources = #ewRadar:getPowerSources()
		local isActive = ewRadar:isActive()
		local connectionNodes = ewRadar:getConnectionNodes()
		local firstRadar = nil
		local radars = ewRadar:getRadars()
		
		--get the first existing radar to prevent issues in calculating the distance later on:
		for i = 1, #radars do
			if radars[i]:isExist() then
				firstRadar = radars[i]
				break
			end
		
		end
		local numDamagedConnectionNodes = 0
		
		
		for j = 1, #connectionNodes do
			local connectionNode = connectionNodes[j]
			if connectionNode:isExist() == false then
				numDamagedConnectionNodes = numDamagedConnectionNodes + 1
			end
		end
		local intactConnectionNodes = numConnectionNodes - numDamagedConnectionNodes
		
		local powerSources = ewRadar:getPowerSources()
		local numDamagedPowerSources = 0
		for j = 1, #powerSources do
			local powerSource = powerSources[j]
			if powerSource:isExist() == false then
				numDamagedPowerSources = numDamagedPowerSources + 1
			end
		end
		local intactPowerSources = numPowerSources - numDamagedPowerSources 
		
		local detectedTargets = ewRadar:getDetectedTargets()
		local samSitesInCoveredArea = ewRadar:getChildRadars()
		
		local unitName = "DESTROYED"
		
		if ewRadar:getDCSRepresentation():isExist() then
			unitName = ewRadar:getDCSName()
		end
		
		self:printOutputToLog("UNIT: "..unitName.." | TYPE: "..ewRadar:getNatoName())
		self:printOutputToLog("ACTIVE: "..tostring(isActive).."| DETECTED TARGETS: "..#detectedTargets.." | DEFENDING HARM: "..tostring(ewRadar:isDefendingHARM()))
		if numConnectionNodes > 0 then
			self:printOutputToLog("CONNECTION NODES: "..numConnectionNodes.." | DAMAGED: "..numDamagedConnectionNodes.." | INTACT: "..intactConnectionNodes)
		else
			self:printOutputToLog("NO CONNECTION NODES SET")
		end
		if numPowerSources > 0 then
			self:printOutputToLog("POWER SOURCES : "..numPowerSources.." | DAMAGED:"..numDamagedPowerSources.." | INTACT: "..intactPowerSources)
		else
			self:printOutputToLog("NO POWER SOURCES SET")
		end
		
		self:printOutputToLog("SAM SITES IN COVERED AREA: "..#samSitesInCoveredArea)
		for j = 1, #samSitesInCoveredArea do
			local samSiteCovered = samSitesInCoveredArea[j]
			self:printOutputToLog(samSiteCovered:getDCSName())
		end
		
		for j = 1, #detectedTargets do
			local contact = detectedTargets[j]
			if firstRadar ~= nil and firstRadar:isExist() then
				local distance = mist.utils.round(mist.utils.metersToNM(ewRadar:getDistanceInMetersToContact(firstRadar:getDCSRepresentation(), contact:getPosition().p)), 2)
				self:printOutputToLog("CONTACT: "..contact:getName().." | TYPE: "..contact:getTypeName().." | DISTANCE NM: "..distance)
			end
		end
		
		self:printOutputToLog("---------------------------------------------------")
		
	end

end

function SkynetIADSLogger:getMetaInfo(abstractElementSupport)
	local info = {}
	info.numSources = #abstractElementSupport
	info.numDamagedSources = 0
	info.numIntactSources = 0
	for j = 1, #abstractElementSupport do
		local source = abstractElementSupport[j]
		if source:isExist() == false then
			info.numDamagedSources = info.numDamagedSources + 1
		end
	end
	info.numIntactSources = info.numSources - info.numDamagedSources
	return info
end

function SkynetIADSLogger:printSAMSiteStatus()
	local samSites = self.iads:getSAMSites()
	
	self:printOutputToLog("------------------------------------------ SAM STATUS: "..self.iads:getCoalitionString().." -------------------------------")
	for i = 1, #samSites do
		local samSite = samSites[i]
		local numConnectionNodes = #samSite:getConnectionNodes()
		local numPowerSources = #samSite:getPowerSources()
		local isAutonomous = samSite:getAutonomousState()
		local isActive = samSite:isActive()
		
		local connectionNodes = samSite:getConnectionNodes()
		local firstRadar = samSite:getRadars()[1]
		local numDamagedConnectionNodes = 0
		for j = 1, #connectionNodes do
			local connectionNode = connectionNodes[j]
			if connectionNode:isExist() == false then
				numDamagedConnectionNodes = numDamagedConnectionNodes + 1
			end
		end
		local intactConnectionNodes = numConnectionNodes - numDamagedConnectionNodes
		
		local powerSources = samSite:getPowerSources()
		local numDamagedPowerSources = 0
		for j = 1, #powerSources do
			local powerSource = powerSources[j]
			if powerSource:isExist() == false then
				numDamagedPowerSources = numDamagedPowerSources + 1
			end
		end
		local intactPowerSources = numPowerSources - numDamagedPowerSources 
		
		local detectedTargets = samSite:getDetectedTargets()
		
		local samSitesInCoveredArea = samSite:getChildRadars()
		
		local engageAirWeapons = samSite:getCanEngageAirWeapons()
		
		local engageHARMS = samSite:getCanEngageHARM()
		
		local hasAmmo = samSite:hasRemainingAmmo()
		local isJammed = samSite:isJammed()
		
		self:printOutputToLog("GROUP: "..samSite:getDCSName().." | TYPE: "..samSite:getNatoName())
		self:printOutputToLog("ACTIVE: "..tostring(isActive).." | JAMMED: "..tostring(isJammed).." | AUTONOMOUS: "..tostring(isAutonomous).." | IS ACTING AS EW: "..tostring(samSite:getActAsEW()).." | CAN ENGAGE AIR WEAPONS : "..tostring(engageAirWeapons).." | CAN ENGAGE HARMS : "..tostring(engageHARMS).." | HAS AMMO: "..tostring(hasAmmo).." | DETECTED TARGETS: "..#detectedTargets.." | DEFENDING HARM: "..tostring(samSite:isDefendingHARM()).." | MISSILES IN FLIGHT: "..tostring(samSite:getNumberOfMissilesInFlight()))
		
		if numConnectionNodes > 0 then
			self:printOutputToLog("CONNECTION NODES: "..numConnectionNodes.." | DAMAGED: "..numDamagedConnectionNodes.." | INTACT: "..intactConnectionNodes)
		else
			self:printOutputToLog("NO CONNECTION NODES SET")
		end
		if numPowerSources > 0 then
			self:printOutputToLog("POWER SOURCES : "..numPowerSources.." | DAMAGED:"..numDamagedPowerSources.." | INTACT: "..intactPowerSources)
		else
			self:printOutputToLog("NO POWER SOURCES SET")
		end
		
		self:printOutputToLog("SAM SITES IN COVERED AREA: "..#samSitesInCoveredArea)
		for j = 1, #samSitesInCoveredArea do
			local samSiteCovered = samSitesInCoveredArea[j]
			self:printOutputToLog(samSiteCovered:getDCSName())
		end
		
		for j = 1, #detectedTargets do
			local contact = detectedTargets[j]
			if firstRadar ~= nil and firstRadar:isExist() then
				local distance = mist.utils.round(mist.utils.metersToNM(samSite:getDistanceInMetersToContact(firstRadar:getDCSRepresentation(), contact:getPosition().p)), 2)
				self:printOutputToLog("CONTACT: "..contact:getName().." | TYPE: "..contact:getTypeName().." | DISTANCE NM: "..distance)
			end
		end
		
		self:printOutputToLog("---------------------------------------------------")
	end
end

function SkynetIADSLogger:printCommandCenterStatus()
	local commandCenters = self.iads:getCommandCenters()
	self:printOutputToLog("------------------------------------------ COMMAND CENTER STATUS: "..self.iads:getCoalitionString().." -------------------------------")
	
	for i = 1, #commandCenters do
		local commandCenter = commandCenters[i]
		local numConnectionNodes = #commandCenter:getConnectionNodes()
		local powerSourceInfo = self:getMetaInfo(commandCenter:getPowerSources())
		local connectionNodeInfo = self:getMetaInfo(commandCenter:getConnectionNodes())
		self:printOutputToLog("GROUP: "..commandCenter:getDCSName().." | TYPE: "..commandCenter:getNatoName())
		if connectionNodeInfo.numSources > 0 then
			self:printOutputToLog("CONNECTION NODES: "..connectionNodeInfo.numSources.." | DAMAGED: "..connectionNodeInfo.numDamagedSources.." | INTACT: "..connectionNodeInfo.numIntactSources)
		else
			self:printOutputToLog("NO CONNECTION NODES SET")
		end
		if powerSourceInfo.numSources > 0 then
			self:printOutputToLog("POWER SOURCES : "..powerSourceInfo.numSources.." | DAMAGED: "..powerSourceInfo.numDamagedSources.." | INTACT: "..powerSourceInfo.numIntactSources)
		else
			self:printOutputToLog("NO POWER SOURCES SET")
		end
		self:printOutputToLog("---------------------------------------------------")
	end
end

function SkynetIADSLogger:printSystemStatus()	

	if self:getDebugSettings().IADSStatus or self:getDebugSettings().contacts then
		local coalitionStr = self.iads:getCoalitionString()
		self:printOutput("---- IADS: "..coalitionStr.." ------")
	end
	
	if self:getDebugSettings().IADSStatus then

		local commandCenters = self.iads:getCommandCenters()
		local numComCenters = #commandCenters
		local numDestroyedComCenters = 0
		local numComCentersNoPower = 0
		local numComCentersNoConnectionNode = 0
		local numIntactComCenters = 0
		for i = 1, #commandCenters do
			local commandCenter = commandCenters[i]
			if commandCenter:hasWorkingPowerSource() == false then
				numComCentersNoPower = numComCentersNoPower + 1
			end
			if commandCenter:hasActiveConnectionNode() == false then
				numComCentersNoConnectionNode = numComCentersNoConnectionNode + 1
			end
			if commandCenter:isDestroyed() == false then
				numIntactComCenters = numIntactComCenters + 1
			end
		end
		
		numDestroyedComCenters = numComCenters - numIntactComCenters
		
		
		self:printOutput("COMMAND CENTERS: "..numComCenters.." | Destroyed: "..numDestroyedComCenters.." | NoPowr: "..numComCentersNoPower.." | NoCon: "..numComCentersNoConnectionNode)
	
		local ewNoPower = 0
		local earlyWarningRadars = self.iads:getEarlyWarningRadars()
		local ewTotal = #earlyWarningRadars
		local ewNoConnectionNode = 0
		local ewActive = 0
		local ewRadarsInactive = 0
		local mobileEWTotal = 0
		local mobileEWCombat = 0
		local mobileEWPatrol = 0
		local mobileEWHarm = 0

		for i = 1, #earlyWarningRadars do
			local ewRadar = earlyWarningRadars[i]
			if ewRadar:hasWorkingPowerSource() == false then
				ewNoPower = ewNoPower + 1
			end
			if ewRadar:hasActiveConnectionNode() == false then
				ewNoConnectionNode = ewNoConnectionNode + 1
			end
			if ewRadar:isActive() then
				ewActive = ewActive + 1
			end
			if SkynetIADSMobilePatrol and SkynetIADSMobilePatrol.getEntryForElement then
				local entry = SkynetIADSMobilePatrol.getEntryForElement(ewRadar)
				if entry and entry.kind == "MEW" then
					mobileEWTotal = mobileEWTotal + 1
					if entry.state == "patrolling" then
						mobileEWPatrol = mobileEWPatrol + 1
					elseif entry.state == "harm_evading" then
						mobileEWHarm = mobileEWHarm + 1
					else
						mobileEWCombat = mobileEWCombat + 1
					end
				end
			end
		end
		
		ewRadarsInactive = ewTotal - ewActive	
		local numEWRadarsDestroyed = #self.iads:getDestroyedEarlyWarningRadars()
		self:printOutput("EW: "..ewTotal.." | On: "..ewActive.." | Off: "..ewRadarsInactive.." | Destroyed: "..numEWRadarsDestroyed.." | NoPowr: "..ewNoPower.." | NoCon: "..ewNoConnectionNode)
		if mobileEWTotal > 0 then
			self:printOutput("MEW: "..mobileEWTotal.." | Combat: "..mobileEWCombat.." | Patrol: "..mobileEWPatrol.." | HARM: "..mobileEWHarm)
		end
		
		local samSitesInactive = 0
		local samSitesActive = 0
		local samSites = self.iads:getSAMSites()
		local samSitesTotal = #samSites
		local samSitesNoPower = 0
		local samSitesNoConnectionNode = 0
		local samSitesOutOfAmmo = 0
		local samSiteAutonomous = 0
		local samSiteRadarDestroyed = 0
		local samSitesJammed = 0
		local mobileSAMTotal = 0
		local mobileSAMCombat = 0
		local mobileSAMPatrol = 0
		local mobileSAMHarm = 0
		for i = 1, #samSites do
			local samSite = samSites[i]
			if samSite:hasWorkingPowerSource() == false then
				samSitesNoPower = samSitesNoPower + 1
			end
			if samSite:hasActiveConnectionNode() == false then
				samSitesNoConnectionNode = samSitesNoConnectionNode + 1
			end
			if samSite:isActive() then
				samSitesActive = samSitesActive + 1
			end
			if samSite:hasRemainingAmmo() == false then
				samSitesOutOfAmmo = samSitesOutOfAmmo + 1
			end
			if samSite:getAutonomousState() == true then
				samSiteAutonomous = samSiteAutonomous + 1
			end
			if samSite:isJammed() then
				samSitesJammed = samSitesJammed + 1
			end
			if samSite:hasWorkingRadar() == false then
				samSiteRadarDestroyed = samSiteRadarDestroyed + 1
			end
			if SkynetIADSMobilePatrol and SkynetIADSMobilePatrol.getEntryForElement then
				local entry = SkynetIADSMobilePatrol.getEntryForElement(samSite)
				if entry and entry.kind == "MSAM" then
					mobileSAMTotal = mobileSAMTotal + 1
					if entry.state == "patrolling" then
						mobileSAMPatrol = mobileSAMPatrol + 1
					elseif entry.state == "harm_evading" then
						mobileSAMHarm = mobileSAMHarm + 1
					else
						mobileSAMCombat = mobileSAMCombat + 1
					end
				end
			end
		end
		
		samSitesInactive = samSitesTotal - samSitesActive
		self:printOutput("SAM: "..samSitesTotal.." | On: "..samSitesActive.." | Off: "..samSitesInactive.." | Jammed: "..samSitesJammed.." | Autonm: "..samSiteAutonomous.." | Raddest: "..samSiteRadarDestroyed.." | NoPowr: "..samSitesNoPower.." | NoCon: "..samSitesNoConnectionNode.." | NoAmmo: "..samSitesOutOfAmmo)
		if mobileSAMTotal > 0 then
			self:printOutput("MSAM: "..mobileSAMTotal.." | Combat: "..mobileSAMCombat.." | Patrol: "..mobileSAMPatrol.." | HARM: "..mobileSAMHarm)
		end
	end
	
	if self:getDebugSettings().contacts then
		local contacts = self.iads:getContacts()
		if contacts then
			for i = 1, #contacts do
				local contact = contacts[i]
					self:printOutput("CONTACT: "..contact:getName().." | TYPE: "..contact:getTypeName().." | GS: "..tostring(contact:getGroundSpeedInKnots()).." | LAST SEEN: "..contact:getAge())
			end
		end
	end
	
	if self:getDebugSettings().commandCenterStatusEnvOutput then
		self:printCommandCenterStatus()
	end

	if self:getDebugSettings().earlyWarningRadarStatusEnvOutput then
		self:printEarlyWarningRadarStatus()
	end
	
	if self:getDebugSettings().samSiteStatusEnvOutput then
		self:printSAMSiteStatus()
	end

end

end
do

SkynetIADS = {}
SkynetIADS.__index = SkynetIADS

SkynetIADS.database = samTypesDB

function SkynetIADS:create(name)
	local iads = {}
	setmetatable(iads, SkynetIADS)
	iads.radioMenu = nil
	iads.detailedStateMenu = nil
	iads.detailedStatePageMenus = {}
	iads.detailedStatePageSize = 8
	iads.earlyWarningRadars = {}
	iads.samSites = {}
	iads.commandCenters = {}
	iads.ewRadarScanMistTaskID = nil
	iads.coalition = nil
	iads.contacts = {}
	iads.maxTargetAge = 32
	iads.name = name
	iads.harmDetection = SkynetIADSHARMDetection:create(iads)
	iads.logger = SkynetIADSLogger:create(iads)
	if iads.name == nil then
		iads.name = ""
	end
	iads.contactUpdateInterval = 5
	world.addEventHandler(iads)
	return iads
end

function SkynetIADS:onEvent(event)
	if (event.id == world.event.S_EVENT_BIRTH ) then
		env.info("New Object Spawned")
	--	self:addSAMSite(event.initiator:getGroup():getName());
	end
end

function SkynetIADS:setUpdateInterval(interval)
	self.contactUpdateInterval = interval
end

function SkynetIADS:setCoalition(item)
	if item then
		local coalitionID = item:getCoalition()
		if self.coalitionID == nil then
			self.coalitionID = coalitionID
		end
		if self.coalitionID ~= coalitionID then
			self:printOutputToLog("element: "..item:getName().." has a different coalition than the IADS", true)
		end
	end
end

function SkynetIADS:addJammer(jammer)
	table.insert(self.jammers, jammer)
end

function SkynetIADS:getCoalition()
	return self.coalitionID
end

function SkynetIADS:getDestroyedEarlyWarningRadars()
	local destroyedSites = {}
	for i = 1, #self.earlyWarningRadars do
		local ewSite = self.earlyWarningRadars[i]
		if ewSite:isDestroyed() then
			table.insert(destroyedSites, ewSite)
		end
	end
	return destroyedSites
end

function SkynetIADS:getUsableAbstractRadarElemtentsOfTable(abstractRadarTable)
	local usable = {}
	for i = 1, #abstractRadarTable do
		local abstractRadarElement = abstractRadarTable[i]
		if abstractRadarElement:hasActiveConnectionNode() and abstractRadarElement:hasWorkingPowerSource() and abstractRadarElement:isDestroyed() == false then
			table.insert(usable, abstractRadarElement)
		end
	end
	return usable
end

function SkynetIADS:getUsableEarlyWarningRadars()
	return self:getUsableAbstractRadarElemtentsOfTable(self.earlyWarningRadars)
end

function SkynetIADS:createTableDelegator(units) 
	local sites = SkynetIADSTableDelegator:create()
	for i = 1, #units do
		local site = units[i]
		table.insert(sites, site)
	end
	return sites
end

function SkynetIADS:addEarlyWarningRadarsByPrefix(prefix)
	self:deactivateEarlyWarningRadars()
	self.earlyWarningRadars = {}
	for unitName, unit in pairs(mist.DBs.unitsByName) do
		local pos = self:findSubString(unitName, prefix)
		--somehow the MIST unit db contains StaticObject, we check to see we only add Units
		local unit = Unit.getByName(unitName)
		if pos and pos == 1 and unit then
			self:addEarlyWarningRadar(unitName)
		end
	end
	return self:createTableDelegator(self.earlyWarningRadars)
end

function SkynetIADS:addEarlyWarningRadar(earlyWarningRadarUnitName)
	local earlyWarningRadarUnit = Unit.getByName(earlyWarningRadarUnitName)
	if earlyWarningRadarUnit == nil then
		self:printOutputToLog("you have added an EW Radar that does not exist, check name of Unit in Setup and Mission editor: "..earlyWarningRadarUnitName, true)
		return
	end
	self:setCoalition(earlyWarningRadarUnit)
	local ewRadar = nil
	local category = earlyWarningRadarUnit:getDesc().category
	if category == Unit.Category.AIRPLANE or category == Unit.Category.SHIP then
		ewRadar = SkynetIADSAWACSRadar:create(earlyWarningRadarUnit, self)
	else
		ewRadar = SkynetIADSEWRadar:create(earlyWarningRadarUnit, self)
	end
	ewRadar:setupElements()
	ewRadar:setCachedTargetsMaxAge(self:getCachedTargetsMaxAge())	
	-- for performance improvement, if iads is not scanning no update coverage update needs to be done, will be executed once when iads activates
	if self.ewRadarScanMistTaskID ~= nil then
		self:buildRadarCoverageForEarlyWarningRadar(ewRadar)
	end
	ewRadar:setActAsEW(true)
	ewRadar:setToCorrectAutonomousState()
	ewRadar:goLive()
	table.insert(self.earlyWarningRadars, ewRadar)
	if self:getDebugSettings().addedEWRadar then
			self:printOutputToLog("ADDED: "..ewRadar:getDescription())
	end
	return ewRadar
end

function SkynetIADS:getCachedTargetsMaxAge()
	return self.contactUpdateInterval
end

function SkynetIADS:getEarlyWarningRadars()
	return self:createTableDelegator(self.earlyWarningRadars)
end

function SkynetIADS:getEarlyWarningRadarByUnitName(unitName)
	for i = 1, #self.earlyWarningRadars do
		local ewRadar = self.earlyWarningRadars[i]
		if ewRadar:getDCSName() == unitName then
			return ewRadar
		end
	end
end

function SkynetIADS:findSubString(haystack, needle)
	return string.find(haystack, needle, 1, true)
end

function SkynetIADS:addSAMSitesByPrefix(prefix)
	self:deativateSAMSites()
	self.samSites = {}
	for groupName, groupData in pairs(mist.DBs.groupsByName) do
		local pos = self:findSubString(groupName, prefix)
		if pos and pos == 1 then
			--mist returns groups, units and, StaticObjects
			local dcsObject = Group.getByName(groupName)
			if dcsObject and dcsObject:getUnits()[1]:isActive() then
				self:addSAMSite(groupName)
			end
		end
	end
	return self:createTableDelegator(self.samSites)
end

function SkynetIADS:getSAMSitesByPrefix(prefix)
	local returnSams = {}
	for i = 1, #self.samSites do
		local samSite = self.samSites[i]
		local groupName = samSite:getDCSName()
		local pos = self:findSubString(groupName, prefix)
		if pos and pos == 1 then
			table.insert(returnSams, samSite)
		end
	end
	return self:createTableDelegator(returnSams)
end

function SkynetIADS:addSAMSite(samSiteName)
	local samSiteDCS = Group.getByName(samSiteName)
	if samSiteDCS == nil then
		self:printOutputToLog("you have added an SAM Site that does not exist, check name of Group in Setup and Mission editor: "..tostring(samSiteName), true)
		return
	end
	self:setCoalition(samSiteDCS)
	local samSite = SkynetIADSSamSite:create(samSiteDCS, self)
	samSite:setupElements()
	samSite:setCanEngageAirWeapons(true)
	samSite:goLive()
	samSite:setCachedTargetsMaxAge(self:getCachedTargetsMaxAge())
	if samSite:getNatoName() == "UNKNOWN" then
		self:printOutputToLog("you have added an SAM site that Skynet IADS can not handle: "..samSite:getDCSName(), true)
		samSite:cleanUp()
	else
		samSite:goDark()
		table.insert(self.samSites, samSite)
		if self:getDebugSettings().addedSAMSite then
			self:printOutputToLog("ADDED: "..samSite:getDescription())
		end
		-- for performance improvement, if iads is not scanning no update coverage update needs to be done, will be executed once when iads activates
		if self.ewRadarScanMistTaskID ~= nil then
			self:buildRadarCoverageForSAMSite(samSite)
		end
		return samSite
	end 
end

function SkynetIADS:getUsableSAMSites()
	return self:getUsableAbstractRadarElemtentsOfTable(self.samSites)
end

function SkynetIADS:getDestroyedSAMSites()
	local destroyedSites = {}
	for i = 1, #self.samSites do
		local samSite = self.samSites[i]
		if samSite:isDestroyed() then
			table.insert(destroyedSites, samSite)
		end
	end
	return destroyedSites
end

function SkynetIADS:getSAMSites()
	return self:createTableDelegator(self.samSites)
end

function SkynetIADS:getActiveSAMSites()
	local activeSAMSites = {}
	for i = 1, #self.samSites do
		if self.samSites[i]:isActive() then
			table.insert(activeSAMSites, self.samSites[i])
		end
	end
	return activeSAMSites
end

function SkynetIADS:getSAMSiteByGroupName(groupName)
	for i = 1, #self.samSites do
		local samSite = self.samSites[i]
		if samSite:getDCSName() == groupName then
			return samSite
		end
	end
end

function SkynetIADS:getSAMSitesByNatoName(natoName)
	local selectedSAMSites = SkynetIADSTableDelegator:create()
	for i = 1, #self.samSites do
		local samSite = self.samSites[i]
		if samSite:getNatoName() == natoName then
			table.insert(selectedSAMSites, samSite)
		end
	end
	return selectedSAMSites
end

function SkynetIADS:addCommandCenter(commandCenter)
	self:setCoalition(commandCenter)
	local comCenter = SkynetIADSCommandCenter:create(commandCenter, self)
	table.insert(self.commandCenters, comCenter)
	-- when IADS is active the radars will be added to the new command center. If it not active this will happen when radar coverage is built
	if self.ewRadarScanMistTaskID ~= nil then
		self:addRadarsToCommandCenters()
	end
	return comCenter
end

function SkynetIADS:isCommandCenterUsable()
	if #self:getCommandCenters() == 0 then
		return true
	end
	local usableComCenters = self:getUsableAbstractRadarElemtentsOfTable(self:getCommandCenters())
	return (#usableComCenters > 0)
end

function SkynetIADS:getCommandCenters()
	return self.commandCenters
end


function SkynetIADS.evaluateContacts(self)

	local ewRadars = self:getUsableEarlyWarningRadars()
	local samSites = self:getUsableSAMSites()
	
	--will add SAM Sites acting as EW Rardars to the ewRadars array:
	for i = 1, #samSites do
		local samSite = samSites[i]
		--We inform SAM sites that a target update is about to happen. If they have no targets in range after the cycle they go dark
		samSite:targetCycleUpdateStart()
		if samSite:getActAsEW() then
			table.insert(ewRadars, samSite)
		end
		--if the sam site is not in ew mode and active we grab the detected targets right here
		if samSite:isActive() and samSite:getActAsEW() == false then
			local contacts = samSite:getDetectedTargets()
			for j = 1, #contacts do
				local contact = contacts[j]
				self:mergeContact(contact)
			end
		end
	end

	local samSitesToTrigger = {}
	
	for i = 1, #ewRadars do
		local ewRadar = ewRadars[i]
		--call go live in case ewRadar had to shut down (HARM attack)
		ewRadar:goLive()
		-- if an awacs has traveled more than a predeterminded distance we update the autonomous state of the SAMs
		if getmetatable(ewRadar) == SkynetIADSAWACSRadar and ewRadar:isUpdateOfAutonomousStateOfSAMSitesRequired() then
			self:buildRadarCoverageForEarlyWarningRadar(ewRadar)
		end
		local ewContacts = ewRadar:getDetectedTargets()
		if EA18GSkynetJammerBridge and EA18GSkynetJammerBridge.filterEWContacts then
			local filteredContacts = EA18GSkynetJammerBridge.filterEWContacts(ewRadar, ewContacts)
			if filteredContacts ~= nil then
				ewContacts = filteredContacts
			end
		end
		if #ewContacts > 0 then
			local samSitesUnderCoverage = ewRadar:getUsableChildRadars()
			for j = 1, #samSitesUnderCoverage do
				local samSiteUnterCoverage = samSitesUnderCoverage[j]
				-- only if a SAM site is not active we add it to the hash of SAM sites to be iterated later on
				if samSiteUnterCoverage:isActive() == false then
					--we add them to a hash to make sure each SAM site is in the collection only once, reducing the number of loops we conduct later on
					samSitesToTrigger[samSiteUnterCoverage:getDCSName()] = samSiteUnterCoverage
				end
			end
			for j = 1, #ewContacts do
				local contact = ewContacts[j]
				self:mergeContact(contact)
			end
		end
	end

	self:cleanAgedTargets()
	
	for samName, samToTrigger in pairs(samSitesToTrigger) do
		for j = 1, #self.contacts do
			local contact = self.contacts[j]
			-- the DCS Radar only returns enemy aircraft, if that should change a coalition check will be required
			-- currently every type of object in the air is handed of to the SAM site, including missiles
			local description = contact:getDesc()
			local category = description.category
			if category and category ~= Unit.Category.GROUND_UNIT and category ~= Unit.Category.SHIP and category ~= Unit.Category.STRUCTURE then
				samToTrigger:informOfContact(contact)
			end
		end
	end
	
	for i = 1, #samSites do
		local samSite = samSites[i]
		samSite:targetCycleUpdateEnd()
	end
	
	self.harmDetection:setContacts(self:getContacts())
	self.harmDetection:evaluateContacts()
	
	self.logger:printSystemStatus()
end

function SkynetIADS:cleanAgedTargets()
	local contactsToKeep = {}
	for i = 1, #self.contacts do
		local contact = self.contacts[i]
		if contact:getAge() < self.maxTargetAge then
			table.insert(contactsToKeep, contact)
		end
	end
	self.contacts = contactsToKeep
end

--TODO unit test this method:
function SkynetIADS:getAbstracRadarElements()
	local abstractRadarElements = {}
	local ewRadars = self:getEarlyWarningRadars()
	local samSites = self:getSAMSites()
	
	for i = 1, #ewRadars do
		local ewRadar = ewRadars[i]
		table.insert(abstractRadarElements, ewRadar)
	end
	
	for i = 1, #samSites do
		local samSite = samSites[i]
		table.insert(abstractRadarElements, samSite)
	end
	return abstractRadarElements
end


function SkynetIADS:addRadarsToCommandCenters()

	--we clear any existing radars that may have been added earlier
	local comCenters = self:getCommandCenters()
	for i = 1, #comCenters do
		local comCenter = comCenters[i]
		comCenter:clearChildRadars()
	end	
	
	-- then we add child radars to the command centers
	local abstractRadarElements = self:getAbstracRadarElements()
		for i = 1, #abstractRadarElements do
			local abstractRadar = abstractRadarElements[i]
			self:addSingleRadarToCommandCenters(abstractRadar)
		end
end

function SkynetIADS:addSingleRadarToCommandCenters(abstractRadarElement)
	local comCenters = self:getCommandCenters()
	for i = 1, #comCenters do
		local comCenter = comCenters[i]
		comCenter:addChildRadar(abstractRadarElement)
	end	
end

-- this method rebuilds the radar coverage of the IADS, a complete rebuild is only required the first time the IADS is activated
-- during runtime it is sufficient to call buildRadarCoverageForSAMSite or buildRadarCoverageForEarlyWarningRadar method that just updates the IADS for one unit, this saves script execution time
function SkynetIADS:buildRadarCoverage()	
	
	--to build the basic radar coverage we use all SAM sites. Checks if SAM site has power or a connection node is done when using the SAM site later on
	local samSites = self:getSAMSites()
	
	--first we clear all child and parent radars that may have been added previously
	for i = 1, #samSites do
		local samSite = samSites[i]
		samSite:clearChildRadars()
		samSite:clearParentRadars()
	end
	
	local ewRadars = self:getEarlyWarningRadars()
	
	for i = 1, #ewRadars do
		local ewRadar = ewRadars[i]
		ewRadar:clearChildRadars()
	end	
	
	--then we rebuild the radar coverage
	local abstractRadarElements = self:getAbstracRadarElements()
	for i = 1, #abstractRadarElements do
		local abstract = abstractRadarElements[i]
		self:buildRadarCoverageForAbstractRadarElement(abstract)
	end
	
	self:addRadarsToCommandCenters()
	
	--we call this once on all sam sites, to make sure autonomous sites go live when IADS activates
	for i = 1, #samSites do
		local samSite = samSites[i]
		samSite:informChildrenOfStateChange()
	end

end

function SkynetIADS:buildRadarCoverageForAbstractRadarElement(abstractRadarElement)
	local abstractRadarElements = self:getAbstracRadarElements()
	for i = 1, #abstractRadarElements do
		local aElementToCompare = abstractRadarElements[i]
		if aElementToCompare ~= abstractRadarElement then
			if abstractRadarElement:isInRadarDetectionRangeOf(aElementToCompare) then
				self:buildRadarAssociation(aElementToCompare, abstractRadarElement)
			end
			if aElementToCompare:isInRadarDetectionRangeOf(abstractRadarElement) then
				self:buildRadarAssociation(abstractRadarElement, aElementToCompare)
			end
		end
	end
end

function SkynetIADS:buildRadarAssociation(parent, child)
	--chilren should only be SAM sites not EW radars
	if ( getmetatable(child) == SkynetIADSSamSite ) then
		parent:addChildRadar(child)
	end
	--Only SAM Sites should have parent Radars, not EW Radars
	if ( getmetatable(child) == SkynetIADSSamSite ) then
		child:addParentRadar(parent)
	end
end

function SkynetIADS:buildRadarCoverageForSAMSite(samSite)
	self:buildRadarCoverageForAbstractRadarElement(samSite)
	self:addSingleRadarToCommandCenters(samSite)
end

function SkynetIADS:buildRadarCoverageForEarlyWarningRadar(ewRadar)
	self:buildRadarCoverageForAbstractRadarElement(ewRadar)
	self:addSingleRadarToCommandCenters(ewRadar)
end

function SkynetIADS:mergeContact(contact)
	local existingContact = false
	for i = 1, #self.contacts do
		local iadsContact = self.contacts[i]
		if iadsContact:getName() == contact:getName() then
			iadsContact:refresh()
			--these contacts are used in the logger we set a kown harm state of a contact coming from a SAM site. So the logger will show them als HARMs
			contact:setHARMState(iadsContact:getHARMState())
			local radars = contact:getAbstractRadarElementsDetected()
			for j = 1, #radars do
				local radar = radars[j]
				iadsContact:addAbstractRadarElementDetected(radar)
			end
			existingContact = true
		end
	end
	if existingContact == false then
		table.insert(self.contacts, contact)
	end
end


function SkynetIADS:getContacts()
	return self.contacts
end

function SkynetIADS:getDebugSettings()
	return self.logger.debugOutput
end

function SkynetIADS:printOutput(output, typeWarning)
	self.logger:printOutput(output, typeWarning)
end

function SkynetIADS:printOutputToLog(output)
	self.logger:printOutputToLog(output)
end

-- will start going through the Early Warning Radars and SAM sites to check what targets they have detected
function SkynetIADS.activate(self)
	mist.removeFunction(self.ewRadarScanMistTaskID)
	self.ewRadarScanMistTaskID = mist.scheduleFunction(SkynetIADS.evaluateContacts, {self}, 1, self.contactUpdateInterval)
	self:buildRadarCoverage()
end

function SkynetIADS:setupSAMSitesAndThenActivate(setupTime)
	self:activate()
	self.logger:printOutputToLog("DEPRECATED: setupSAMSitesAndThenActivate, no longer needed since using enableEmission instead of AI on / off allows for the Ground units to setup with their radars turned off")
end

function SkynetIADS:deactivate()
	mist.removeFunction(self.ewRadarScanMistTaskID)
	mist.removeFunction(self.samSetupMistTaskID)
	self:deativateSAMSites()
	self:deactivateEarlyWarningRadars()
	self:deactivateCommandCenters()
end

function SkynetIADS:deactivateCommandCenters()
	for i = 1, #self.commandCenters do
		local comCenter = self.commandCenters[i]
		comCenter:cleanUp()
	end
end

function SkynetIADS:deativateSAMSites()
	for i = 1, #self.samSites do
		local samSite = self.samSites[i]
		samSite:cleanUp()
	end
end

function SkynetIADS:deactivateEarlyWarningRadars()
	for i = 1, #self.earlyWarningRadars do
		local ewRadar = self.earlyWarningRadars[i]
		ewRadar:cleanUp()
	end
end	

function SkynetIADS:addRadioMenu()
	self.radioMenu = missionCommands.addSubMenu('SKYNET IADS '..self:getCoalitionString())
	local displayIADSStatus = missionCommands.addCommand('show IADS Status', self.radioMenu, SkynetIADS.updateDisplay, {self = self, value = true, option = 'IADSStatus'})
	local displayIADSStatus = missionCommands.addCommand('hide IADS Status', self.radioMenu, SkynetIADS.updateDisplay, {self = self, value = false, option = 'IADSStatus'})
	local displayIADSStatus = missionCommands.addCommand('show contacts', self.radioMenu, SkynetIADS.updateDisplay, {self = self, value = true, option = 'contacts'})
	local displayIADSStatus = missionCommands.addCommand('hide contacts', self.radioMenu, SkynetIADS.updateDisplay, {self = self, value = false, option = 'contacts'})
	self.detailedStateMenu = missionCommands.addSubMenu('Detailed State', self.radioMenu)
	missionCommands.addCommand('Refresh List', self.detailedStateMenu, SkynetIADS.rebuildDetailedStateMenu, self)
	self:rebuildDetailedStateMenu()
end

function SkynetIADS:removeRadioMenu()
	missionCommands.removeItem(self.radioMenu)
end

function SkynetIADS.showDetailedSAMState(params)
	local self = params.self
	local groupName = params.groupName
	local samSite = self:getSAMSiteByGroupName(groupName)
	if samSite == nil then
		trigger.action.outText("Detailed State | SAM site not found: "..tostring(groupName), 10)
		return
	end
	trigger.action.outText(self.logger:buildDetailedSAMSiteReport(samSite), 18)
end

function SkynetIADS:rebuildDetailedStateMenu()
	if self.detailedStatePageMenus then
		for i = 1, #self.detailedStatePageMenus do
			missionCommands.removeItem(self.detailedStatePageMenus[i])
		end
	end
	self.detailedStatePageMenus = {}

	if self.detailedStateMenu == nil then
		return
	end

	local samSites = {}
	for i = 1, #self.samSites do
		samSites[#samSites + 1] = self.samSites[i]
	end
	table.sort(samSites, function(a, b)
		return a:getDCSName() < b:getDCSName()
	end)

	local pageSize = self.detailedStatePageSize or 8
	local pageCount = math.max(1, math.ceil(#samSites / pageSize))
	for pageIndex = 1, pageCount do
		local pageMenu = missionCommands.addSubMenu('Page '..pageIndex, self.detailedStateMenu)
		self.detailedStatePageMenus[#self.detailedStatePageMenus + 1] = pageMenu
		local startIndex = ((pageIndex - 1) * pageSize) + 1
		local endIndex = math.min(pageIndex * pageSize, #samSites)
		if startIndex > endIndex then
			missionCommands.addCommand('No SAM Sites', pageMenu, function()
				trigger.action.outText("Detailed State | no SAM sites registered", 8)
			end)
		else
			for i = startIndex, endIndex do
				local samSite = samSites[i]
				missionCommands.addCommand(samSite:getDCSName(), pageMenu, SkynetIADS.showDetailedSAMState, {
					self = self,
					groupName = samSite:getDCSName()
				})
			end
		end
	end
end

function SkynetIADS.updateDisplay(params)
	local option = params.option
	local self = params.self
	local value = params.value
	if option == 'IADSStatus' then
		self:getDebugSettings()[option] = value
	elseif option == 'contacts' then
		self:getDebugSettings()[option] = value
	end
end

function SkynetIADS:getCoalitionString()
	local coalitionStr = "RED"
	if self.coalitionID == coalition.side.BLUE then
		coalitionStr = "BLUE"
	elseif self.coalitionID == coalition.side.NEUTRAL then
		coalitionStr = "NEUTRAL"
	end
		
	if self.name then
		coalitionStr = "COALITION: "..coalitionStr.." | NAME: "..self.name
	end
	
	return coalitionStr
end

function SkynetIADS:getMooseConnector()
	if self.mooseConnector == nil then
		self.mooseConnector = SkynetMooseA2ADispatcherConnector:create(self)
	end
	return self.mooseConnector
end

function SkynetIADS:addMooseSetGroup(mooseSetGroup)
	self:getMooseConnector():addMooseSetGroup(mooseSetGroup)
end

end
do

SkynetMooseA2ADispatcherConnector = {}

function SkynetMooseA2ADispatcherConnector:create(iads)
	local instance = {}
	setmetatable(instance, self)
	self.__index = self
	instance.iadsCollection = {}
	instance.mooseGroups = {}
	instance.ewRadarGroupNames = {}
	instance.samSiteGroupNames = {}
	table.insert(instance.iadsCollection, iads)
	return instance
end

function SkynetMooseA2ADispatcherConnector:addIADS(iads)
	table.insert(self.iadsCollection, iads)
end

function SkynetMooseA2ADispatcherConnector:addMooseSetGroup(mooseSetGroup)
	table.insert(self.mooseGroups, mooseSetGroup)
	self:update()
end

function SkynetMooseA2ADispatcherConnector:getEarlyWarningRadarGroupNames()
	self.ewRadarGroupNames = {}
	for i = 1, #self.iadsCollection do
		local ewRadars = self.iadsCollection[i]:getUsableEarlyWarningRadars()
		for j = 1, #ewRadars do
			local ewRadar = ewRadars[j]
			table.insert(self.ewRadarGroupNames, ewRadar:getDCSRepresentation():getGroup():getName())
		end
	end
	return self.ewRadarGroupNames
end

function SkynetMooseA2ADispatcherConnector:getSAMSiteGroupNames()
	self.samSiteGroupNames = {}
	for i = 1, #self.iadsCollection do
		local samSites = self.iadsCollection[i]:getUsableSAMSites()
		for j = 1, #samSites do
			local samSite = samSites[j]
			table.insert(self.samSiteGroupNames, samSite:getDCSName())
		end
	end
	return self.samSiteGroupNames
end

function SkynetMooseA2ADispatcherConnector:update()
	
	--mooseGroup elements are type of:
	--https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Core.Set.html##(SET_GROUP)
	
	--remove previously set group names:
	for i = 1, #self.mooseGroups do
		local mooseGroup = self.mooseGroups[i]
		mooseGroup:RemoveGroupsByName(self.ewRadarGroupNames)
		mooseGroup:RemoveGroupsByName(self.samSiteGroupNames)
	end
	
	--add group names of IADS radars that are currently usable by the IADS:
	for i = 1, #self.mooseGroups do
		local mooseGroup = self.mooseGroups[i]
		mooseGroup:AddGroupsByName(self:getEarlyWarningRadarGroupNames())
		mooseGroup:AddGroupsByName(self:getSAMSiteGroupNames())
	end
end

end
do


SkynetIADSTableDelegator = {}

function SkynetIADSTableDelegator:create()
	local instance = {}
	local forwarder = {}
	forwarder.__index = function(tbl, name)
		tbl[name] = function(self, ...)
				for i = 1, #self do
					self[i][name](self[i], ...)
				end
				return self
			end
		return tbl[name]
	end
	setmetatable(instance, forwarder)
	instance.__index = forwarder
	return instance
end

end
do

SkynetIADSAbstractDCSObjectWrapper = {}

function SkynetIADSAbstractDCSObjectWrapper:create(dcsRepresentation)
	local instance = {}
	setmetatable(instance, self)
	self.__index = self
	instance.dcsName = ""
	instance.typeName = ""
	instance:setDCSRepresentation(dcsRepresentation)
	if getmetatable(dcsRepresentation) ~= Group then
		instance.typeName = dcsRepresentation:getTypeName()
	end
	return instance
end

function SkynetIADSAbstractDCSObjectWrapper:setDCSRepresentation(representation)
	self.dcsRepresentation = representation
	if self.dcsRepresentation then
		self.dcsName = self.dcsRepresentation:getName()
		if (self.dcsName == nil or string.len(self.dcsName) == 0) and self.dcsRepresentation.id_ then
			self.dcsName = self.dcsRepresentation.id_
		end
	end
end

function SkynetIADSAbstractDCSObjectWrapper:getDCSRepresentation()
	return self.dcsRepresentation
end

function SkynetIADSAbstractDCSObjectWrapper:getName()
	return self.dcsName
end

function SkynetIADSAbstractDCSObjectWrapper:getTypeName()
	return self.typeName
end

function SkynetIADSAbstractDCSObjectWrapper:getPosition()
	return self.dcsRepresentation:getPosition()
end

function SkynetIADSAbstractDCSObjectWrapper:isExist()
	if self.dcsRepresentation then
		return self.dcsRepresentation:isExist()
	else
		return false
	end
end

function SkynetIADSAbstractDCSObjectWrapper:insertToTableIfNotAlreadyAdded(tbl, object)
	local isAdded = false
	for i = 1, #tbl do
		local child = tbl[i]
		if child == object then
			isAdded = true
		end
	end
	if isAdded == false then
		table.insert(tbl, object)
	end
	return not isAdded
end

-- helper code for class inheritance
function inheritsFrom( baseClass )

    local new_class = {}
    local class_mt = { __index = new_class }

    function new_class:create()
        local newinst = {}
        setmetatable( newinst, class_mt )
        return newinst
    end

    if nil ~= baseClass then
        setmetatable( new_class, { __index = baseClass } )
    end

    -- Implementation of additional OO properties starts here --

    -- Return the class object of the instance
    function new_class:class()
        return new_class
    end

    -- Return the super class object of the instance
    function new_class:superClass()
        return baseClass
    end

    -- Return true if the caller is an instance of theClass
    function new_class:isa( theClass )
        local b_isa = false

        local cur_class = new_class

        while ( nil ~= cur_class ) and ( false == b_isa ) do
            if cur_class == theClass then
                b_isa = true
            else
                cur_class = cur_class:superClass()
            end
        end

        return b_isa
    end

    return new_class
end


end

do

SkynetIADSAbstractElement = {}
SkynetIADSAbstractElement = inheritsFrom(SkynetIADSAbstractDCSObjectWrapper)

function SkynetIADSAbstractElement:create(dcsRepresentation, iads)
	local instance = self:superClass():create(dcsRepresentation)
	setmetatable(instance, self)
	self.__index = self
	instance.connectionNodes = {}
	instance.powerSources = {}
	instance.iads = iads
	instance.natoName = "UNKNOWN"
	world.addEventHandler(instance)
	return instance
end

function SkynetIADSAbstractElement:removeEventHandlers()
	world.removeEventHandler(self)
end

function SkynetIADSAbstractElement:cleanUp()
	self:removeEventHandlers()
end

function SkynetIADSAbstractElement:isDestroyed()
	return self:getDCSRepresentation():isExist() == false
end

function SkynetIADSAbstractElement:addPowerSource(powerSource)
	table.insert(self.powerSources, powerSource)
	self:informChildrenOfStateChange()
	return self
end

function SkynetIADSAbstractElement:getPowerSources()
	return self.powerSources
end

function SkynetIADSAbstractElement:addConnectionNode(connectionNode)
	table.insert(self.connectionNodes, connectionNode)
	self:informChildrenOfStateChange()
	return self
end

function SkynetIADSAbstractElement:getConnectionNodes()
	return self.connectionNodes
end

function SkynetIADSAbstractElement:hasActiveConnectionNode()
	local connectionNode = self:genericCheckOneObjectIsAlive(self.connectionNodes)
	if connectionNode == false and self.iads:getDebugSettings().samNoConnection then
		self.iads:printOutput(self:getDescription().." no connection to Command Center")
	end
	return connectionNode
end

function SkynetIADSAbstractElement:hasWorkingPowerSource()
	local power = self:genericCheckOneObjectIsAlive(self.powerSources)
	if power == false and self.iads:getDebugSettings().hasNoPower then
		self.iads:printOutput(self:getDescription().." has no power")
	end
	return power
end

function SkynetIADSAbstractElement:getDCSName()
	return self.dcsName
end

-- generic function to theck if power plants, command centers, connection nodes are still alive
function SkynetIADSAbstractElement:genericCheckOneObjectIsAlive(objects)
	local isAlive = (#objects == 0)
	for i = 1, #objects do
		local object = objects[i]
		--if we find one object that is not fully destroyed we assume the IADS is still working
		if object:isExist() then
			isAlive = true
			break
		end
	end
	return isAlive
end

function SkynetIADSAbstractElement:getNatoName()
	return self.natoName
end

function SkynetIADSAbstractElement:getDescription()
	return "IADS ELEMENT: "..self:getDCSName().." | Type: "..tostring(self:getNatoName())
end

function SkynetIADSAbstractElement:onEvent(event)
	--if a unit is destroyed we check to see if its a power plant powering the unit or a connection node
	if event.id == world.event.S_EVENT_DEAD then
		if self:hasWorkingPowerSource() == false or self:isDestroyed() then
			self:goDark()
			self:informChildrenOfStateChange()
		end
		if self:hasActiveConnectionNode() == false then
			self:informChildrenOfStateChange()
		end
	end
	if event.id == world.event.S_EVENT_SHOT then
		self:weaponFired(event)
	end
end

--placeholder method, can be implemented by subclasses
function SkynetIADSAbstractElement:weaponFired(event)
	
end

--placeholder method, can be implemented by subclasses
function SkynetIADSAbstractElement:goDark()
	
end

--placeholder method, can be implemented by subclasses
function SkynetIADSAbstractElement:goAutonomous()

end

--placeholder method, can be implemented by subclasses
function SkynetIADSAbstractElement:setToCorrectAutonomousState()

end

--placeholder method, can be implemented by subclasses
function SkynetIADSAbstractElement:informChildrenOfStateChange()
	
end

end
do

SkynetIADSAbstractRadarElement = {}
SkynetIADSAbstractRadarElement = inheritsFrom(SkynetIADSAbstractElement)

SkynetIADSAbstractRadarElement.AUTONOMOUS_STATE_DCS_AI = 1
SkynetIADSAbstractRadarElement.AUTONOMOUS_STATE_DARK = 2

SkynetIADSAbstractRadarElement.GO_LIVE_WHEN_IN_KILL_ZONE = 1
SkynetIADSAbstractRadarElement.GO_LIVE_WHEN_IN_SEARCH_RANGE = 2

SkynetIADSAbstractRadarElement.HARM_TO_SAM_ASPECT = 5
SkynetIADSAbstractRadarElement.HARM_LOOKAHEAD_NM = 20

function SkynetIADSAbstractRadarElement:create(dcsElementWithRadar, iads)
	local instance = self:superClass():create(dcsElementWithRadar, iads)
	setmetatable(instance, self)
	self.__index = self
	instance.aiState = false
	instance.harmScanID = nil
	instance.harmSilenceID = nil
	instance.lastJammerUpdate = 0
	instance.objectsIdentifiedAsHarms = {}
	instance.objectsIdentifiedAsHarmsMaxTargetAge = 60
	instance.launchers = {}
	instance.trackingRadars = {}
	instance.searchRadars = {}
	instance.parentRadars = {}
	instance.childRadars = {}
	instance.missilesInFlight = {}
	instance.pointDefences = {}
	instance.harmDecoys = {}
	instance.autonomousBehaviour = SkynetIADSAbstractRadarElement.AUTONOMOUS_STATE_DCS_AI
	instance.goLiveRange = SkynetIADSAbstractRadarElement.GO_LIVE_WHEN_IN_KILL_ZONE
	instance.isAutonomous = true
	instance.harmDetectionChance = 0
	instance.minHarmShutdownTime = 0
	instance.maxHarmShutDownTime = 0
	instance.minHarmPresetShutdownTime = 30
	instance.maxHarmPresetShutdownTime = 180
	instance.harmShutdownTime = 0
	instance.harmRelocationMinDistanceMeters = 180
	instance.harmRelocationMaxDistanceMeters = 320
	instance.harmRelocationFallbackSpeedKmph = 60
	instance.harmRelocationCheckInterval = 1
	instance.harmRelocationArrivalToleranceMeters = 35
	instance.harmRelocationInProgress = false
	instance.harmRelocationDestination = nil
	instance.harmRelocationDeadline = 0
	instance.harmRelocationPlannedDistanceMeters = 0
	instance.harmRelocationStartPoint = nil
	instance.harmRelocationMinimumCompletionMeters = 0
	instance.harmReactionCooldownSeconds = 3
	instance.harmReactionLockUntil = 0
	instance.firingRangePercent = 100
	instance.actAsEW = false
	instance.cachedTargets = {}
	instance.cachedTargetsMaxAge = 1
	instance.cachedTargetsCurrentAge = 0
	instance.goLiveTime = 0
	instance.engageAirWeapons = false
	instance.isAPointDefence = false
	instance.canEngageHARM = false
	instance.dataBaseSupportedTypesCanEngageHARM = false
	-- 5 seconds seems to be a good value for the sam site to find the target with its organic radar
	instance.noCacheActiveForSecondsAfterGoLive = 5
	return instance
end

--TODO: this method could be updated to only return Radar weapons fired, this way a SAM firing an IR weapon could go dark faster in the goDark() method
function SkynetIADSAbstractRadarElement:weaponFired(event)
	if event.id == world.event.S_EVENT_SHOT then
		local weapon = event.weapon
		local launcherFired = event.initiator
		for i = 1, #self.launchers do
			local launcher = self.launchers[i]
			if launcher:getDCSRepresentation() == launcherFired then
				table.insert(self.missilesInFlight, weapon)
			end
		end
	end
end

function SkynetIADSAbstractRadarElement:setCachedTargetsMaxAge(maxAge)
	self.cachedTargetsMaxAge = maxAge
end

function SkynetIADSAbstractRadarElement:cleanUp()
	for i = 1, #self.pointDefences do
		local pointDefence = self.pointDefences[i]
		pointDefence:cleanUp()
	end
	mist.removeFunction(self.harmScanID)
	mist.removeFunction(self.harmSilenceID)
	--call method from super class
	self:removeEventHandlers()
end

function SkynetIADSAbstractRadarElement:setIsAPointDefence(state)
	if (state == true or state == false) then
		self.isAPointDefence = state
	end
end

function SkynetIADSAbstractRadarElement:getIsAPointDefence()
	return self.isAPointDefence
end

function SkynetIADSAbstractRadarElement:addPointDefence(pointDefence)
	table.insert(self.pointDefences, pointDefence)
	pointDefence:setIsAPointDefence(true)
	return self
end

function SkynetIADSAbstractRadarElement:getPointDefences()
	return self.pointDefences
end

function SkynetIADSAbstractRadarElement:addHARMDecoy(harmDecoy)
	table.insert(self.harmDecoys, harmDecoy)
end

function SkynetIADSAbstractRadarElement:addParentRadar(parentRadar)
	self:insertToTableIfNotAlreadyAdded(self.parentRadars, parentRadar)
	self:informChildrenOfStateChange()
end

function SkynetIADSAbstractRadarElement:getParentRadars()
	return self.parentRadars
end

function SkynetIADSAbstractRadarElement:clearParentRadars()
	self.parentRadars = {}
end

function SkynetIADSAbstractRadarElement:addChildRadar(childRadar)
	self:insertToTableIfNotAlreadyAdded(self.childRadars, childRadar)
end

function SkynetIADSAbstractRadarElement:getChildRadars()
	return self.childRadars
end

function SkynetIADSAbstractRadarElement:clearChildRadars()
	self.childRadars = {}
end

--TODO: unit test this method
function SkynetIADSAbstractRadarElement:getUsableChildRadars()
	local usableRadars = {}
	for i = 1, #self.childRadars do
		local childRadar = self.childRadars[i]
		if childRadar:hasWorkingPowerSource() and childRadar:hasActiveConnectionNode() then
			table.insert(usableRadars, childRadar)
		end
	end	
	return usableRadars
end

function SkynetIADSAbstractRadarElement:informChildrenOfStateChange()
	self:setToCorrectAutonomousState()
	local children = self:getChildRadars()
	for i = 1, #children do
		local childRadar = children[i]
		childRadar:setToCorrectAutonomousState()
	end
	self.iads:getMooseConnector():update()
end

function SkynetIADSAbstractRadarElement:setToCorrectAutonomousState()
	local parents = self:getParentRadars()
	for i = 1, #parents do
		local parent = parents[i]
		--of one parent exists that still is connected to the IADS, the SAM site does not have to go autonomous
		--instead of isDestroyed() write method, hasWorkingSearchRadars()
		if self:hasActiveConnectionNode() and self.iads:isCommandCenterUsable() and parent:hasWorkingPowerSource() and parent:hasActiveConnectionNode() and parent:getActAsEW() == true and parent:isDestroyed() == false then
			self:resetAutonomousState()
			return
		end
	end
	self:goAutonomous()
end


function SkynetIADSAbstractRadarElement:setAutonomousBehaviour(mode)
	if mode ~= nil then
		self.autonomousBehaviour = mode
	end
	return self
end

function SkynetIADSAbstractRadarElement:getAutonomousBehaviour()
	return self.autonomousBehaviour
end

function SkynetIADSAbstractRadarElement:resetAutonomousState()
	self.isAutonomous = false
	self:goDark()
end

function SkynetIADSAbstractRadarElement:goAutonomous()
	self.isAutonomous = true
	if self.autonomousBehaviour == SkynetIADSAbstractRadarElement.AUTONOMOUS_STATE_DARK then
		self:goDark()
	else
		self:goLive()
	end
end

function SkynetIADSAbstractRadarElement:getAutonomousState()
	return self.isAutonomous
end

function SkynetIADSAbstractRadarElement:pointDefencesHaveRemainingAmmo(minNumberOfMissiles)
	local remainingMissiles = 0
	for i = 1, #self.pointDefences do
		local pointDefence = self.pointDefences[i]
		remainingMissiles = remainingMissiles + pointDefence:getRemainingNumberOfMissiles()
	end
	return self:hasRequiredNumberOfMissiles(minNumberOfMissiles, remainingMissiles)
end

function SkynetIADSAbstractRadarElement:hasRequiredNumberOfMissiles(minNumberOfMissiles, remainingMissiles)
	local returnValue = false
	if ( remainingMissiles > 0 and remainingMissiles >= minNumberOfMissiles ) then
		returnValue = true
	end
	return returnValue
end

function SkynetIADSAbstractRadarElement:hasRemainingAmmoToEngageMissiles(minNumberOfMissiles)
	local remainingMissiles = self:getRemainingNumberOfMissiles()
	return self:hasRequiredNumberOfMissiles(minNumberOfMissiles, remainingMissiles)
end

-- this method needs to be refactored so that it works for ew radars that don't have launchers, or that it is only called by sam sites
function SkynetIADSAbstractRadarElement:hasEnoughLaunchersToEngageMissiles(minNumberOfLaunchers)
	local launchers = self:getLaunchers()
	if(launchers ~= nil) then
	 launchers = #self:getLaunchers()
	else 
		launchers = 0
	end
	return self:hasRequiredNumberOfMissiles(minNumberOfLaunchers, launchers)
end

function SkynetIADSAbstractRadarElement:pointDefencesHaveEnoughLaunchers(minNumberOfLaunchers)
	local numOfLaunchers = 0
	for i = 1, #self.pointDefences do
		local pointDefence = self.pointDefences[i]
		numOfLaunchers = numOfLaunchers + #pointDefence:getLaunchers()	
	end
	return self:hasRequiredNumberOfMissiles(minNumberOfLaunchers, numOfLaunchers)
end

function SkynetIADSAbstractRadarElement:setIgnoreHARMSWhilePointDefencesHaveAmmo(state)
	self.iads:printOutputToLog("DEPRECATED: setIgnoreHARMSWhilePointDefencesHaveAmmo SAM Site will stay live automaticall as long as itself or it's point defences can defend against a HARM")
	return self
end

function SkynetIADSAbstractRadarElement:hasMissilesInFlight()
	return #self.missilesInFlight > 0
end

function SkynetIADSAbstractRadarElement:getNumberOfMissilesInFlight()
	return #self.missilesInFlight
end

-- DCS does not send an event, when a missile is destroyed, so this method needs to be polled so that the missiles in flight are current, polling is done in the HARM Search call: evaluateIfTargetsContainHARMs
function SkynetIADSAbstractRadarElement:updateMissilesInFlight()
	local missilesInFlight = {}
	for i = 1, #self.missilesInFlight do
		local missile = self.missilesInFlight[i]
		if missile:isExist() then
			table.insert(missilesInFlight, missile)
		end
	end
	self.missilesInFlight = missilesInFlight
	self:goDarkIfOutOfAmmo()
end

function SkynetIADSAbstractRadarElement:goDarkIfOutOfAmmo()
	if self:hasRemainingAmmo() == false and self:getActAsEW() == false then
		self:goDark()
	end
end

function SkynetIADSAbstractRadarElement:getActAsEW()
	return self.actAsEW
end	

function SkynetIADSAbstractRadarElement:setActAsEW(ewState)
	if ewState == true or ewState == false then
		local stateChange = false
		if ewState ~= self.actAsEW then
			stateChange = true
		end
		self.actAsEW = ewState
		if stateChange then
			self:informChildrenOfStateChange()
		end
	end
	if self.actAsEW == true then
		self:goLive()
	else
		self:goDark()
	end
	return self
end

function SkynetIADSAbstractRadarElement:getUnitsToAnalyse()
	local units = {}
	table.insert(units, self:getDCSRepresentation())
	if getmetatable(self:getDCSRepresentation()) == Group then
		units = self:getDCSRepresentation():getUnits()
	end
	return units
end

function SkynetIADSAbstractRadarElement:getRemainingNumberOfMissiles()
	local remainingNumberOfMissiles = 0
	for i = 1, #self.launchers do
		local launcher = self.launchers[i]
		remainingNumberOfMissiles = remainingNumberOfMissiles + launcher:getRemainingNumberOfMissiles()
	end
	return remainingNumberOfMissiles
end

function SkynetIADSAbstractRadarElement:getInitialNumberOfMissiles()
	local initalNumberOfMissiles = 0
	for i = 1, #self.launchers do
		local launcher = self.launchers[i]
		initalNumberOfMissiles = launcher:getInitialNumberOfMissiles() + initalNumberOfMissiles
	end
	return initalNumberOfMissiles
end

function SkynetIADSAbstractRadarElement:getRemainingNumberOfShells()
	local remainingNumberOfShells = 0
	for i = 1, #self.launchers do
		local launcher = self.launchers[i]
		remainingNumberOfShells = remainingNumberOfShells + launcher:getRemainingNumberOfShells()
	end
	return remainingNumberOfShells
end

function SkynetIADSAbstractRadarElement:getInitialNumberOfShells()
	local initialNumberOfShells = 0
	for i = 1, #self.launchers do
		local launcher = self.launchers[i]
		initialNumberOfShells = initialNumberOfShells + launcher:getInitialNumberOfShells()
	end
	return initialNumberOfShells
end

function SkynetIADSAbstractRadarElement:hasRemainingAmmo()
	--the launcher check is due to ew radars they have no launcher and no ammo and therefore are never out of ammo
	return ( #self.launchers == 0 ) or ((self:getRemainingNumberOfMissiles() > 0 ) or ( self:getRemainingNumberOfShells() > 0 ) )
end

function SkynetIADSAbstractRadarElement:getHARMDetectionChance()
	return self.harmDetectionChance
end

function SkynetIADSAbstractRadarElement:setHARMDetectionChance(chance)
	if chance and chance >= 0 and chance <= 100 then
		self.harmDetectionChance = chance
	end
	return self
end

function SkynetIADSAbstractRadarElement:setupElements()
	local numUnits = #self:getUnitsToAnalyse()
	for typeName, dataType in pairs(SkynetIADS.database) do
		local hasSearchRadar = false
		local hasTrackingRadar = false
		local hasLauncher = false
		local searchRadarOptional = dataType['searchRadarOptional'] == true
		self.searchRadars = {}
		self.trackingRadars = {}
		self.launchers = {}
		for entry, unitData in pairs(dataType) do
			if entry == 'searchRadar' then
				self:analyseAndAddUnit(SkynetIADSSAMSearchRadar, self.searchRadars, unitData)
				hasSearchRadar = true
			end
			if entry == 'launchers' then
				self:analyseAndAddUnit(SkynetIADSSAMLauncher, self.launchers, unitData)
				hasLauncher = true
			end
			if entry == 'trackingRadar' then
				self:analyseAndAddUnit(SkynetIADSSAMTrackingRadar, self.trackingRadars, unitData)
				hasTrackingRadar = true
			end
		end
		
		--this check ensures a unit or group has all required elements for the specific sam or ew type:
		if (hasLauncher and hasSearchRadar and hasTrackingRadar and #self.launchers > 0 and #self.searchRadars > 0  and #self.trackingRadars > 0 ) 
			or (hasSearchRadar and hasLauncher and #self.searchRadars > 0 and #self.launchers > 0)
			or (searchRadarOptional and hasLauncher and #self.launchers > 0) then
			self:setHARMDetectionChance(dataType['harm_detection_chance'])
			self.dataBaseSupportedTypesCanEngageHARM = dataType['can_engage_harm'] 
			self:setCanEngageHARM(self.dataBaseSupportedTypesCanEngageHARM)
			local natoName = dataType['name']['NATO']
			self:buildNatoName(natoName)
			break
		end	
	end
end

function SkynetIADSAbstractRadarElement:setCanEngageHARM(canEngage)
	if canEngage == true or canEngage == false then
		self.canEngageHARM = canEngage
		if ( canEngage == true and self:getCanEngageAirWeapons() == false ) then
			self:setCanEngageAirWeapons(true)
		end
	end
	return self
end

function SkynetIADSAbstractRadarElement:getCanEngageHARM()
	return self.canEngageHARM
end

function SkynetIADSAbstractRadarElement:setCanEngageAirWeapons(engageAirWeapons)
	if self:isDestroyed() == false then
		local controller = self:getDCSRepresentation():getController()
		if ( engageAirWeapons == true ) then
			controller:setOption(AI.Option.Ground.id.ENGAGE_AIR_WEAPONS, true)
			--its important that we set var to true here, to prevent recursion in setCanEngageHARM
			self.engageAirWeapons = true
			--we set the original value we got when loading info about the SAM site
			self:setCanEngageHARM(self.dataBaseSupportedTypesCanEngageHARM)
		else
			controller:setOption(AI.Option.Ground.id.ENGAGE_AIR_WEAPONS, false)
			self:setCanEngageHARM(false)
			self.engageAirWeapons = false
		end
	end
	return self
end

function SkynetIADSAbstractRadarElement:getCanEngageAirWeapons()
	return self.engageAirWeapons
end

function SkynetIADSAbstractRadarElement:buildNatoName(natoName)
	--we shorten the SA-XX names and don't return their code names eg goa, gainful..
	local pos = natoName:find(" ")
	local prefix = natoName:sub(1, 2)
	if string.lower(prefix) == 'sa' and pos ~= nil then
		self.natoName = natoName:sub(1, (pos-1))
	else
		self.natoName = natoName
	end
end

function SkynetIADSAbstractRadarElement:analyseAndAddUnit(class, tableToAdd, unitData)
	local units = self:getUnitsToAnalyse()
	for i = 1, #units do
		local unit = units[i]
		self:buildSingleUnit(unit, class, tableToAdd, unitData)
	end
end

function SkynetIADSAbstractRadarElement:buildSingleUnit(unit, class, tableToAdd, unitData)
	local unitTypeName = unit:getTypeName()
	for unitName, unitPerformanceData in pairs(unitData) do
		if unitName == unitTypeName then
			samElement = class:create(unit)
			samElement:setupRangeData()
			table.insert(tableToAdd, samElement)
		end
	end
end

local setControllerAlarmState

function SkynetIADSAbstractRadarElement:getController()
	local dcsRepresentation = self:getDCSRepresentation()
	if dcsRepresentation:isExist() then
		return dcsRepresentation:getController()
	else
		return nil
	end
end

function SkynetIADSAbstractRadarElement:getHARMRelocationGroup()
	local dcsRepresentation = self:getDCSRepresentation()
	if dcsRepresentation == nil or dcsRepresentation:isExist() == false then
		return nil
	end

	local okUnits, units = pcall(function()
		return dcsRepresentation:getUnits()
	end)
	if okUnits and units and #units > 0 then
		return dcsRepresentation
	end

	local okGroup, group = pcall(function()
		return dcsRepresentation:getGroup()
	end)
	if okGroup and group and group:isExist() then
		return group
	end

	return nil
end

function SkynetIADSAbstractRadarElement:getHARMRelocationController()
	local group = self:getHARMRelocationGroup()
	if group and group:isExist() then
		return group:getController()
	end
	return nil
end

function SkynetIADSAbstractRadarElement:isHARMRelocationPointOnLand(point)
	if point == nil then
		return false
	end
	if land == nil or land.getSurfaceType == nil or land.SurfaceType == nil or land.SurfaceType.LAND == nil then
		return true
	end
	local ok, surfaceType = pcall(function()
		return land.getSurfaceType({
			x = point.x,
			y = point.z
		})
	end)
	if ok ~= true then
		return true
	end
	return surfaceType == land.SurfaceType.LAND
end

function SkynetIADSAbstractRadarElement:calculateRandomHARMRelocationPoint(minDistanceMeters, maxDistanceMeters)
	local group = self:getHARMRelocationGroup()
	if group == nil then
		return nil, 0, nil
	end

	local startPoint = mist.getLeadPos(group)
	if startPoint == nil then
		return nil, 0, nil
	end

	local fallbackPoint = nil
	local fallbackDistance = 0
	for i = 1, 50 do
		local distanceMeters = math.random(minDistanceMeters, maxDistanceMeters)
		local headingRad = math.random() * 2 * math.pi
		local candidate = {
			x = startPoint.x + math.cos(headingRad) * distanceMeters,
			y = startPoint.y,
			z = startPoint.z + math.sin(headingRad) * distanceMeters
		}
		if fallbackPoint == nil then
			fallbackPoint = candidate
			fallbackDistance = distanceMeters
		end
		if self:isHARMRelocationPointOnLand(candidate) then
			return candidate, distanceMeters, startPoint
		end
	end

	return fallbackPoint, fallbackDistance, startPoint
end

function SkynetIADSAbstractRadarElement:issueHARMRelocationRoute(group, destination, speedKmph)
	if group == nil or group:isExist() == false or destination == nil then
		return false
	end

	local startPoint = mist.getLeadPos(group)
	if startPoint == nil then
		return false
	end

	local speedMps = mist.utils.kmphToMps(speedKmph or self:getHARMRelocationSpeedKmph())
	local path = {
		mist.ground.buildWP(startPoint, "Diamond", speedMps),
		mist.ground.buildWP({
			x = startPoint.x + 25,
			z = startPoint.z + 25
		}, "Diamond", speedMps),
		mist.ground.buildWP(destination, "Diamond", speedMps)
	}

	local ok = pcall(function()
		mist.goRoute(group, path)
	end)

	return ok == true
end

function SkynetIADSAbstractRadarElement:getHARMRelocationSpeedKmph()
	local group = self:getHARMRelocationGroup()
	if group and group:isExist() then
		local units = group:getUnits()
		for i = 1, #units do
			local unit = units[i]
			if unit and unit:isExist() then
				local okDesc, desc = pcall(function()
					return unit:getDesc()
				end)
				if okDesc and desc and desc.speedMax and desc.speedMax > 0 then
					return math.max(self.harmRelocationFallbackSpeedKmph, math.floor(desc.speedMax * 3.6 + 0.5))
				end
			end
		end
	end
	return self.harmRelocationFallbackSpeedKmph
end

function SkynetIADSAbstractRadarElement:calculateHARMRelocationTravelTimeSeconds(distanceMeters, speedKmph)
	local speedMps = mist.utils.kmphToMps(speedKmph or self:getHARMRelocationSpeedKmph())
	if speedMps <= 0 then
		speedMps = 1
	end
	return math.max(10, math.ceil(distanceMeters / speedMps) + 6)
end

function SkynetIADSAbstractRadarElement:enterHARMRelocationDarkState()
	if self:isDestroyed() == false then
		self:getDCSRepresentation():enableEmission(false)
	end

	local movementController = self:getHARMRelocationController()
	if movementController then
		pcall(function()
			movementController:setOnOff(true)
		end)
		setControllerAlarmState(movementController, false)
	end

	local controller = self:getController()
	if controller and controller ~= movementController then
		pcall(function()
			controller:setOnOff(true)
		end)
		setControllerAlarmState(controller, false)
	end

	self:pointDefencesGoLive()
	self.aiState = false
	self:stopScanningForHARMs()
	self.cachedTargets = {}
end

function SkynetIADSAbstractRadarElement:attemptHARMRelocation()
	local group = self:getHARMRelocationGroup()
	if group == nil or group:isExist() == false then
		return false, 0, nil
	end

	local speedKmph = self:getHARMRelocationSpeedKmph()
	local destination, distanceMeters, startPoint = self:calculateRandomHARMRelocationPoint(
		self.harmRelocationMinDistanceMeters,
		self.harmRelocationMaxDistanceMeters
	)
	if destination == nil then
		return false, 0, nil
	end

	if self:issueHARMRelocationRoute(group, destination, speedKmph) ~= true then
		return false, 0, nil
	end

	local travelTime = self:calculateHARMRelocationTravelTimeSeconds(distanceMeters, speedKmph)
	self.harmRelocationInProgress = true
	self.harmRelocationPlannedDistanceMeters = distanceMeters
	self.harmRelocationDestination = destination
	self.harmRelocationDeadline = timer.getTime() + travelTime
	self.harmRelocationStartPoint = startPoint
	self.harmRelocationMinimumCompletionMeters = math.max(80, math.floor(distanceMeters * 0.6))
	return true, travelTime, destination, speedKmph, distanceMeters
end

function SkynetIADSAbstractRadarElement:getHARMRelocationDistanceMovedMeters()
	if self.harmRelocationStartPoint == nil then
		return 0
	end

	local group = self:getHARMRelocationGroup()
	if group == nil or group:isExist() == false then
		return 0
	end

	local currentPoint = mist.getLeadPos(group)
	if currentPoint == nil then
		return 0
	end

	return mist.utils.get2DDist(currentPoint, self.harmRelocationStartPoint)
end

function SkynetIADSAbstractRadarElement:hasReachedHARMRelocationDestination()
	if self.harmRelocationDestination == nil then
		return true
	end

	local group = self:getHARMRelocationGroup()
	if group == nil or group:isExist() == false then
		return true
	end

	local currentPoint = mist.getLeadPos(group)
	if currentPoint == nil then
		return true
	end

	local distance = mist.utils.get2DDist(currentPoint, self.harmRelocationDestination)
	return distance <= self.harmRelocationArrivalToleranceMeters
end

function SkynetIADSAbstractRadarElement.checkHARMRelocationArrival(self)
	if self.harmRelocationInProgress ~= true then
		self:finishHarmDefence(self)
		return
	end

	local timedOut = timer.getTime() >= self.harmRelocationDeadline
	local movedDistance = self:getHARMRelocationDistanceMovedMeters()
	local movedEnough = movedDistance >= (self.harmRelocationMinimumCompletionMeters or 0)
	if self:hasReachedHARMRelocationDestination() or (timedOut and movedEnough) then
		if self.iads:getDebugSettings().harmDefence then
			local reason = timedOut and "timeout_moved" or "arrived"
			self.iads:printOutputToLog("HARM DEFENCE RELOCATION COMPLETE: "..self:getDCSName().." | REASON: "..reason)
		end
		self:finishHarmDefence(self)
	elseif timedOut then
		self.harmRelocationDeadline = timer.getTime() + math.max(5, self.harmRelocationCheckInterval)
		if self.iads:getDebugSettings().harmDefence then
			self.iads:printOutputToLog(
				"HARM DEFENCE RELOCATION WAITING: "
				..self:getDCSName()
				.." | MOVED: "..mist.utils.round(movedDistance, 0)
				.."m | REQUIRED: "..tostring(self.harmRelocationMinimumCompletionMeters)
				.."m"
			)
		end
	end
end

function SkynetIADSAbstractRadarElement:getLaunchers()
	return self.launchers
end

function SkynetIADSAbstractRadarElement:getSearchRadars()
	return self.searchRadars
end

function SkynetIADSAbstractRadarElement:getTrackingRadars()
	return self.trackingRadars
end

function SkynetIADSAbstractRadarElement:getEmitterRepresentations()
	local emitterRepresentations = {}
	local alreadyAdded = {}

	local function addRepresentation(wrapper)
		if wrapper == nil or wrapper.getDCSRepresentation == nil then
			return
		end

		local representation = wrapper:getDCSRepresentation()
		if representation == nil or representation.isExist == nil or representation:isExist() == false then
			return
		end

		local key = tostring(representation)
		local okName, name = pcall(function()
			return representation:getName()
		end)
		if okName and name then
			key = name
		end

		if alreadyAdded[key] ~= true then
			alreadyAdded[key] = true
			table.insert(emitterRepresentations, representation)
		end
	end

	for i = 1, #self.searchRadars do
		addRepresentation(self.searchRadars[i])
	end
	for i = 1, #self.trackingRadars do
		addRepresentation(self.trackingRadars[i])
	end
	for i = 1, #self.launchers do
		addRepresentation(self.launchers[i])
	end

	return emitterRepresentations
end

function SkynetIADSAbstractRadarElement:getRadars()
	local radarUnits = {}	
	for i = 1, #self.searchRadars do
		table.insert(radarUnits, self.searchRadars[i])
	end	
	for i = 1, #self.trackingRadars do
		table.insert(radarUnits, self.trackingRadars[i])
	end
	if #radarUnits == 0 then
		for i = 1, #self.launchers do
			local launcher = self.launchers[i]
			if launcher.canProvideRadarCoverage and launcher:canProvideRadarCoverage() then
				table.insert(radarUnits, launcher)
			end
		end
	end
	return radarUnits
end

function SkynetIADSAbstractRadarElement:setGoLiveRangeInPercent(percent)
	if percent ~= nil then
		self.firingRangePercent = percent	
		for i = 1, #self.launchers do
			local launcher = self.launchers[i]
			launcher:setFiringRangePercent(self.firingRangePercent)
		end
		for i = 1, #self.searchRadars do
			local radar = self.searchRadars[i]
			radar:setFiringRangePercent(self.firingRangePercent)
		end
	end
	return self
end

function SkynetIADSAbstractRadarElement:getGoLiveRangeInPercent()
	return self.firingRangePercent
end

function SkynetIADSAbstractRadarElement:setEngagementZone(engagementZone)
	if engagementZone == SkynetIADSAbstractRadarElement.GO_LIVE_WHEN_IN_KILL_ZONE then
		self.goLiveRange = engagementZone
	elseif engagementZone == SkynetIADSAbstractRadarElement.GO_LIVE_WHEN_IN_SEARCH_RANGE then
		self.goLiveRange = engagementZone
	end
	return self
end

function SkynetIADSAbstractRadarElement:getEngagementZone()
	return self.goLiveRange
end

local function setControllerROE(controller, weaponHold)
	local groundValue = weaponHold and AI.Option.Ground.val.ROE.WEAPON_HOLD or AI.Option.Ground.val.ROE.WEAPON_FREE
	local airValue = weaponHold and AI.Option.Air.val.ROE.WEAPON_HOLD or AI.Option.Air.val.ROE.WEAPON_FREE
	pcall(function()
		controller:setOption(AI.Option.Ground.id.ROE, groundValue)
	end)
	pcall(function()
		controller:setOption(AI.Option.Air.id.ROE, airValue)
	end)
end

setControllerAlarmState = function(controller, redState)
	local alarmValue = redState and AI.Option.Ground.val.ALARM_STATE.RED or AI.Option.Ground.val.ALARM_STATE.GREEN
	pcall(function()
		controller:setOption(AI.Option.Ground.id.ALARM_STATE, alarmValue)
	end)
end

function SkynetIADSAbstractRadarElement:goLive()
	if ( self.aiState == false and self:hasWorkingPowerSource() and self.harmSilenceID == nil) 
	and (self:hasRemainingAmmo() == true  )
	then
		if self:isDestroyed() == false then
			local  cont = self:getController()
			cont:setOnOff(true)
			setControllerAlarmState(cont, true)
			setControllerROE(cont, false)
			self:getDCSRepresentation():enableEmission(true)
			local emitters = self:getEmitterRepresentations()
			for i = 1, #emitters do
				local emitter = emitters[i]
				pcall(function()
					local emitterController = emitter:getController()
					if emitterController then
						emitterController:setOnOff(true)
						setControllerAlarmState(emitterController, true)
						setControllerROE(emitterController, false)
					end
					emitter:enableEmission(true)
				end)
			end
			self.goLiveTime = timer.getTime()
			self.aiState = true
		end
		self:pointDefencesStopActingAsEW()
		if  self.iads:getDebugSettings().radarWentLive then
			self.iads:printOutputToLog("GOING LIVE: "..self:getDescription())
		end
		self:scanForHarms()
	end
end

function SkynetIADSAbstractRadarElement:pointDefencesStopActingAsEW()
	for i = 1, #self.pointDefences do
		local pointDefence = self.pointDefences[i]
		pointDefence:setActAsEW(false)
	end
end


function SkynetIADSAbstractRadarElement:goDark()
	if (self:hasWorkingPowerSource() == false) or ( self.aiState == true ) 
	and (self.harmSilenceID ~= nil or ( self.harmSilenceID == nil and #self:getDetectedTargets() == 0 and self:hasMissilesInFlight() == false) or ( self.harmSilenceID == nil and #self:getDetectedTargets() > 0 and self:hasMissilesInFlight() == false and self:hasRemainingAmmo() == false ) )	
	then
		if self:isDestroyed() == false then
			self:getDCSRepresentation():enableEmission(false)
			local emitters = self:getEmitterRepresentations()
			for i = 1, #emitters do
				local emitter = emitters[i]
				pcall(function()
					local emitterController = emitter:getController()
					if emitterController then
						setControllerAlarmState(emitterController, false)
						setControllerROE(emitterController, true)
					end
					emitter:enableEmission(false)
				end)
			end
		end
		-- point defence will only go live if the Radar Emitting site it is protecting goes dark and this is due to a it defending against a HARM
		if (self.harmSilenceID ~= nil) then
			self:pointDefencesGoLive()
			if self:isDestroyed() == false then
				--if site goes dark due to HARM we turn off AI, this is due to a bug in DCS multiplayer where the harm will find its way to the radar emitter if just setEmissions is set to false
				local controller = self:getController()
				controller:setOnOff(false)
			end
		end
		self.aiState = false
		self:stopScanningForHARMs()
		self.cachedTargets = {}
		if self.iads:getDebugSettings().radarWentDark then
			self.iads:printOutputToLog("GOING DARK: "..self:getDescription())
		end
	end
end

function SkynetIADSAbstractRadarElement:pointDefencesGoLive()
	local setActive = false
	for i = 1, #self.pointDefences do
		local pointDefence = self.pointDefences[i]
		if ( pointDefence:getActAsEW() == false ) then
			setActive = true
			pointDefence:setActAsEW(true)
		end
	end
	return setActive
end

function SkynetIADSAbstractRadarElement:isActive()
	return self.aiState
end

function SkynetIADSAbstractRadarElement:isJammed()
	return self.lastJammerUpdate > 0 and (timer.getTime() - self.lastJammerUpdate) <= 10
end

function SkynetIADSAbstractRadarElement:isTargetInRange(target)

	local isSearchRadarInRange = false
	local isTrackingRadarInRange = false
	local isLauncherInRange = false
	
	local isSearchRadarInRange = ( #self.searchRadars == 0 )
	for i = 1, #self.searchRadars do
		local searchRadar = self.searchRadars[i]
		if searchRadar:isInRange(target) then
			isSearchRadarInRange = true
			break
		end
	end
	
	if self.goLiveRange == SkynetIADSAbstractRadarElement.GO_LIVE_WHEN_IN_KILL_ZONE then
		
		isLauncherInRange = ( #self.launchers == 0 )
		for i = 1, #self.launchers do
			local launcher = self.launchers[i]
			if launcher:isInRange(target) then
				isLauncherInRange = true
				break
			end
		end
		
		isTrackingRadarInRange = ( #self.trackingRadars == 0 )
		for i = 1, #self.trackingRadars do
			local trackingRadar = self.trackingRadars[i]
			if trackingRadar:isInRange(target) then
				isTrackingRadarInRange = true
				break
			end
		end
	else
		isLauncherInRange = true
		isTrackingRadarInRange = true
	end
	return  (isSearchRadarInRange and isTrackingRadarInRange and isLauncherInRange )
end

function SkynetIADSAbstractRadarElement:isInRadarDetectionRangeOf(abstractRadarElement)
	local radars = self:getRadars()
	local abstractRadarElementRadars = abstractRadarElement:getRadars()
	for i = 1, #radars do
		local radar = radars[i]
		for j = 1, #abstractRadarElementRadars do
			local abstractRadarElementRadar = abstractRadarElementRadars[j]
			if  abstractRadarElementRadar:isExist() and radar:isExist() then
				local distance = self:getDistanceToUnit(radar:getDCSRepresentation():getPosition().p, abstractRadarElementRadar:getDCSRepresentation():getPosition().p)	
				if abstractRadarElementRadar:getMaxRangeFindingTarget() >= distance then
					return true
				end
			end
		end
	end
	return false
end

function SkynetIADSAbstractRadarElement:getDistanceToUnit(unitPosA, unitPosB)
	return mist.utils.round(mist.utils.get2DDist(unitPosA, unitPosB, 0))
end

function SkynetIADSAbstractRadarElement:hasWorkingRadar()
	local radars = self:getRadars()
	for i = 1, #radars do
		local radar = radars[i]
		if radar:isRadarWorking() == true then
			return true
		end
	end
	return false
end

function SkynetIADSAbstractRadarElement:jam(successProbability)
		if self:isDestroyed() == false then
			local controller = self:getController()
			local probability = math.random(1, 100)
			if self.iads:getDebugSettings().jammerProbability then
				self.iads:printOutputToLog("JAMMER: "..self:getDescription()..": Probability: "..successProbability)
			end
			local jamSucceeded = successProbability > probability
			if jamSucceeded then
				setControllerROE(controller, true)
				if self.iads:getDebugSettings().jammerProbability then
					self.iads:printOutputToLog("JAMMER: "..self:getDescription()..": jammed, setting to weapon hold")
				end
			else
				setControllerROE(controller, false)
				if self.iads:getDebugSettings().jammerProbability then
					self.iads:printOutputToLog("JAMMER: "..self:getDescription()..": jammed, setting to weapon free")
				end
			end
			if EA18GSkynetJammerBridge and EA18GSkynetJammerBridge.onJamResult then
				pcall(EA18GSkynetJammerBridge.onJamResult, self, successProbability, jamSucceeded)
			end
			self.lastJammerUpdate = timer:getTime()
		end
end

function SkynetIADSAbstractRadarElement:scanForHarms()
	self:stopScanningForHARMs()
	self.harmScanID = mist.scheduleFunction(SkynetIADSAbstractRadarElement.evaluateIfTargetsContainHARMs, {self}, 1, 2)
end

function SkynetIADSAbstractRadarElement:isScanningForHARMs()
	return self.harmScanID ~= nil
end

function SkynetIADSAbstractRadarElement:isDefendingHARM()
	return self.harmSilenceID ~= nil
end

function SkynetIADSAbstractRadarElement:stopScanningForHARMs()
	mist.removeFunction(self.harmScanID)
	self.harmScanID = nil
end

function SkynetIADSAbstractRadarElement:goSilentToEvadeHARM(timeToImpact)
	local now = timer.getTime()
	if self.harmSilenceID ~= nil or self.harmRelocationInProgress == true then
		return false
	end
	if self.harmReactionLockUntil ~= nil and now < self.harmReactionLockUntil then
		return false
	end
	self.harmReactionLockUntil = now + self.harmReactionCooldownSeconds
	if ( timeToImpact == nil ) then
		timeToImpact = 0
	end

	local relocated, travelTime, _, speedKmph, distanceMeters = self:attemptHARMRelocation()
	if relocated == true then
		self.harmShutdownTime = travelTime
		if self.iads:getDebugSettings().harmDefence then
			self.iads:printOutputToLog("HARM DEFENCE SHUTDOWN + RELOCATE: "..self:getDCSName().." | DIST: "..distanceMeters.."m | SPEED: "..speedKmph.."km/h | ETA: "..self.harmShutdownTime.." seconds | TTI: "..timeToImpact)
		end
		self.harmSilenceID = mist.scheduleFunction(
			SkynetIADSAbstractRadarElement.checkHARMRelocationArrival,
			{self},
			timer.getTime() + self.harmRelocationCheckInterval,
			self.harmRelocationCheckInterval
		)
		self:enterHARMRelocationDarkState()
		return true
	end

	self.minHarmShutdownTime = self:calculateMinimalShutdownTimeInSeconds(timeToImpact)
	self.maxHarmShutDownTime = self:calculateMaximalShutdownTimeInSeconds(self.minHarmShutdownTime)

	self.harmShutdownTime = self:calculateHARMShutdownTime()
	if self.iads:getDebugSettings().harmDefence then
		self.iads:printOutputToLog("HARM DEFENCE SHUTTING DOWN: "..self:getDCSName().." | FOR: "..self.harmShutdownTime.." seconds | TTI: "..timeToImpact)
	end
	self.harmSilenceID = mist.scheduleFunction(SkynetIADSAbstractRadarElement.finishHarmDefence, {self}, timer.getTime() + self.harmShutdownTime, 1)
	self:goDark()
	return true
end

function SkynetIADSAbstractRadarElement:getHARMShutdownTime()
	return self.harmShutdownTime
end

function SkynetIADSAbstractRadarElement:calculateHARMShutdownTime()
	local shutDownTime = math.random(self.minHarmShutdownTime, self.maxHarmShutDownTime)
	return shutDownTime
end

function SkynetIADSAbstractRadarElement.finishHarmDefence(self)
	mist.removeFunction(self.harmSilenceID)
	self.harmSilenceID = nil
	self.harmShutdownTime = 0
	self.harmRelocationInProgress = false
	self.harmRelocationDestination = nil
	self.harmRelocationDeadline = 0
	self.harmRelocationPlannedDistanceMeters = 0
	self.harmRelocationStartPoint = nil
	self.harmRelocationMinimumCompletionMeters = 0
	self.harmReactionLockUntil = timer.getTime() + self.harmReactionCooldownSeconds

	self:setToCorrectAutonomousState()
end

function SkynetIADSAbstractRadarElement:getDetectedTargets()
	if ( timer.getTime() - self.cachedTargetsCurrentAge > self.cachedTargetsMaxAge ) or ( timer.getTime() - self.goLiveTime < self.noCacheActiveForSecondsAfterGoLive ) then
		self.cachedTargets = {}
		self.cachedTargetsCurrentAge = timer.getTime()
		if self:hasWorkingPowerSource() and self:isDestroyed() == false then
			local targets = self:getController():getDetectedTargets(Controller.Detection.RADAR)
			for i = 1, #targets do
				local target = targets[i]
				-- there are cases when a destroyed object is still visible as a target to the radar, don't add it, will cause errors everywhere the dcs object is accessed
				if target.object then
					local iadsTarget = SkynetIADSContact:create(target, self)
					iadsTarget:refresh()
					if self:isTargetInRange(iadsTarget) then
						table.insert(self.cachedTargets, iadsTarget)
					end
				end
			end
		end
	end
	return self.cachedTargets
end

function SkynetIADSAbstractRadarElement:getSecondsToImpact(distanceNM, speedKT)
	local tti = 0
	if speedKT > 0 then
		tti = mist.utils.round((distanceNM / speedKT) * 3600, 0)
		if tti < 0 then
			tti = 0
		end
	end
	return tti
end

function SkynetIADSAbstractRadarElement:getDistanceInMetersToContact(radarUnit, point)
	return mist.utils.round(mist.utils.get3DDist(radarUnit:getPosition().p, point), 0)
end

function SkynetIADSAbstractRadarElement:calculateMinimalShutdownTimeInSeconds(timeToImpact)
	return timeToImpact + self.minHarmPresetShutdownTime
end

function SkynetIADSAbstractRadarElement:calculateMaximalShutdownTimeInSeconds(minShutdownTime)	
	return minShutdownTime + mist.random(1, self.maxHarmPresetShutdownTime)
end

function SkynetIADSAbstractRadarElement:calculateImpactPoint(target, distanceInMeters)
	-- distance needs to be incremented by a certain value for ip calculation to work, check why presumably due to rounding errors in the previous distance calculation
	return land.getIP(target:getPosition().p, target:getPosition().x, distanceInMeters + 50)
end

function SkynetIADSAbstractRadarElement:shallReactToHARM()
	return self.harmDetectionChance >=  math.random(1, 100)
end

-- will only check for missiles, if DCS ads AAA than can engage HARMs then this code must be updated:
function SkynetIADSAbstractRadarElement:shallIgnoreHARMShutdown()
	local numOfHarms = self:getNumberOfObjectsItentifiedAsHARMS()
	--[[
	self.iads:printOutputToLog("Self enough launchers: "..tostring(self:hasEnoughLaunchersToEngageMissiles(numOfHarms)))
	self.iads:printOutputToLog("Self enough missiles: "..tostring(self:hasRemainingAmmoToEngageMissiles(numOfHarms)))
	self.iads:printOutputToLog("PD enough missiles: "..tostring(self:pointDefencesHaveRemainingAmmo(numOfHarms)))
	self.iads:printOutputToLog("PD enough launchers: "..tostring(self:pointDefencesHaveEnoughLaunchers(numOfHarms)))
	--]]
	return ( ((self:hasEnoughLaunchersToEngageMissiles(numOfHarms) and self:hasRemainingAmmoToEngageMissiles(numOfHarms) and self:getCanEngageHARM()) or (self:pointDefencesHaveRemainingAmmo(numOfHarms) and self:pointDefencesHaveEnoughLaunchers(numOfHarms))))
end

function SkynetIADSAbstractRadarElement:informOfHARM(harmContact)
	local siblingCoordClass = rawget(_G, "SkynetIADSSiblingCoordination")
	if siblingCoordClass and siblingCoordClass.getFamilyForElement then
		local siblingInfo = siblingCoordClass.getFamilyForElement(self)
		if siblingInfo and siblingInfo.role == "passive" then
			return
		end
	end
	local directTargetGroupName = harmContact and harmContact._skynetDirectTargetGroupName or nil
	if directTargetGroupName ~= nil and self:getDCSName() ~= directTargetGroupName then
		return
	end
	if self:isActive() == false and self.harmSilenceID == nil and self.harmRelocationInProgress ~= true then
		return
	end
	if directTargetGroupName ~= nil and self:getDCSName() == directTargetGroupName then
		self:addObjectIdentifiedAsHARM(harmContact)
		local speedKT = harmContact:getGroundSpeedInKnots(0)
		local radarReference = nil
		local radars = self:getRadars()
		for i = 1, #radars do
			if radars[i]:isExist() then
				radarReference = radars[i]
				break
			end
		end
		if radarReference == nil then
			radarReference = self:getDCSRepresentation()
		end
		local distanceNM = 0
		if radarReference and radarReference.isExist and radarReference:isExist() then
			distanceNM = mist.utils.metersToNM(self:getDistanceInMetersToContact(radarReference, harmContact:getPosition().p))
		end
		local secondsToImpact = self:getSecondsToImpact(distanceNM, speedKT)
		if ( self:getIsAPointDefence() == false and ( self:isDefendingHARM() == false or ( self:getHARMShutdownTime() < secondsToImpact ) ) and self:shallIgnoreHARMShutdown() == false) then
			self:goSilentToEvadeHARM(secondsToImpact)
		end
		return
	end
	local radars = self:getRadars()
		for j = 1, #radars do
			local radar = radars[j]
			if radar:isExist() then
				local distanceNM =  mist.utils.metersToNM(self:getDistanceInMetersToContact(radar, harmContact:getPosition().p))
				local harmToSAMHeading = mist.utils.toDegree(mist.utils.getHeadingPoints(harmContact:getPosition().p, radar:getPosition().p))
				local harmToSAMAspect = self:calculateAspectInDegrees(harmContact:getMagneticHeading(), harmToSAMHeading)
				local speedKT = harmContact:getGroundSpeedInKnots(0)
				local secondsToImpact = self:getSecondsToImpact(distanceNM, speedKT)
				--TODO: use tti instead of distanceNM?
				-- when iterating through the radars, store shortest tti and work with that value??
				--TODO: 使用tti而不是distanceNM？
				-- 在遍历雷达时，存储最短tti并使用该值？？
				if ( harmToSAMAspect < SkynetIADSAbstractRadarElement.HARM_TO_SAM_ASPECT and distanceNM < SkynetIADSAbstractRadarElement.HARM_LOOKAHEAD_NM ) then
					self:addObjectIdentifiedAsHARM(harmContact)
					if ( #self:getPointDefences() > 0 and self:pointDefencesGoLive() == true and self.iads:getDebugSettings().harmDefence ) then
							self.iads:printOutputToLog("POINT DEFENCES GOING LIVE FOR: "..self:getDCSName().." | TTI: "..secondsToImpact)
					end
					--self.iads:printOutputToLog("Ignore HARM shutdown: "..tostring(self:shallIgnoreHARMShutdown()))
					--self.iads:printOutputToLog("忽略HARM关闭："..tostring(self:shallIgnoreHARMShutdown()))
					if ( self:getIsAPointDefence() == false and ( self:isDefendingHARM() == false or ( self:getHARMShutdownTime() < secondsToImpact ) ) and self:shallIgnoreHARMShutdown() == false) then
						self:goSilentToEvadeHARM(secondsToImpact)
						break
					end
				end
			end
		end
end

function SkynetIADSAbstractElement:addObjectIdentifiedAsHARM(harmContact)
	self:insertToTableIfNotAlreadyAdded(self.objectsIdentifiedAsHarms, harmContact)
end

function SkynetIADSAbstractRadarElement:calculateAspectInDegrees(harmHeading, harmToSAMHeading)
		local aspect = harmHeading - harmToSAMHeading
		if ( aspect < 0 ) then
			aspect = -1 * aspect
		end
		if aspect > 180 then
			aspect = 360 - aspect
		end
		return mist.utils.round(aspect)
end

function SkynetIADSAbstractRadarElement:getNumberOfObjectsItentifiedAsHARMS()
	return #self.objectsIdentifiedAsHarms
end

function SkynetIADSAbstractRadarElement:cleanUpOldObjectsIdentifiedAsHARMS()
	local newHARMS = {}
	for i = 1, #self.objectsIdentifiedAsHarms do
		local harmContact = self.objectsIdentifiedAsHarms[i]
		if harmContact:getAge() < self.objectsIdentifiedAsHarmsMaxTargetAge then
			table.insert(newHARMS, harmContact)
		end
	end
	--stop point defences acting as ew (always on), will occur if activated via evaluateIfTargetsContainHARMs()
	--if in this iteration all harms where cleared we turn of the point defence. But in any other cases we dont turn of point defences, that interferes with other parts of the iads
	-- when setting up the iads (letting pds go to read state)
	if (#newHARMS == 0 and self:getNumberOfObjectsItentifiedAsHARMS() > 0 ) then
		self:pointDefencesStopActingAsEW()
	end
	self.objectsIdentifiedAsHarms = newHARMS
end


function SkynetIADSAbstractRadarElement.evaluateIfTargetsContainHARMs(self)

	--if an emitter dies the SAM site being jammed will revert back to normal operation:
	if self.lastJammerUpdate > 0 and ( timer:getTime() - self.lastJammerUpdate ) > 10 then
		self:jam(0)
		self.lastJammerUpdate = 0
	end
	
	--we use the regular interval of this method to update to other states: 
	self:updateMissilesInFlight()	
	self:cleanUpOldObjectsIdentifiedAsHARMS()
end

end
do
--this class is currently used for AWACS and Ships, at a latter date a separate class for ships could be created, currently not needed
SkynetIADSAWACSRadar = {}
SkynetIADSAWACSRadar = inheritsFrom(SkynetIADSAbstractRadarElement)

function SkynetIADSAWACSRadar:create(radarUnit, iads)
	local instance = self:superClass():create(radarUnit, iads)
	setmetatable(instance, self)
	self.__index = self
	instance.lastUpdatePosition = nil
	instance.natoName = radarUnit:getTypeName()
	return instance
end

function SkynetIADSAWACSRadar:setupElements()
	local unit = self:getDCSRepresentation()
	local radar = SkynetIADSSAMSearchRadar:create(unit)
	radar:setupRangeData()
	table.insert(self.searchRadars, radar)
end


-- AWACs will not scan for HARMS
function SkynetIADSAWACSRadar:scanForHarms()
	
end

function SkynetIADSAWACSRadar:getMaxAllowedMovementForAutonomousUpdateInNM()
	--local radarRange = mist.utils.metersToNM(self.searchRadars[1]:getMaxRangeFindingTarget())
	--return mist.utils.round(radarRange / 10)
	--fixed to 10 nm miles to better fit small SAM sites
	return 10
end

function SkynetIADSAWACSRadar:isUpdateOfAutonomousStateOfSAMSitesRequired()
	local isUpdateRequired = self:getDistanceTraveledSinceLastUpdate() > self:getMaxAllowedMovementForAutonomousUpdateInNM()
	if isUpdateRequired then
		self.lastUpdatePosition = nil
	end
	return isUpdateRequired
end

function SkynetIADSAWACSRadar:getDistanceTraveledSinceLastUpdate()
	local currentPosition = nil
	if self.lastUpdatePosition == nil and self:getDCSRepresentation():isExist() then
		self.lastUpdatePosition = self:getDCSRepresentation():getPosition().p
	end
	if self:getDCSRepresentation():isExist() then
		currentPosition = self:getDCSRepresentation():getPosition().p
	end
	return mist.utils.round(mist.utils.metersToNM(self:getDistanceToUnit(self.lastUpdatePosition, currentPosition)))
end

end

do
SkynetIADSCommandCenter = {}
SkynetIADSCommandCenter = inheritsFrom(SkynetIADSAbstractRadarElement)

function SkynetIADSCommandCenter:create(commandCenter, iads)
	local instance = self:superClass():create(commandCenter, iads)
	setmetatable(instance, self)
	self.__index = self
	instance.natoName = "COMMAND CENTER"
	return instance
end

function SkynetIADSCommandCenter:goDark()

end

function SkynetIADSCommandCenter:goLive()

end

end
do

SkynetIADSContact = {}
SkynetIADSContact = inheritsFrom(SkynetIADSAbstractDCSObjectWrapper)

SkynetIADSContact.CLIMB = "CLIMB"
SkynetIADSContact.DESCEND = "DESCEND"

SkynetIADSContact.HARM = "HARM"
SkynetIADSContact.NOT_HARM = "NOT_HARM"
SkynetIADSContact.HARM_UNKNOWN = "HARM_UNKNOWN"

function SkynetIADSContact:create(dcsRadarTarget, abstractRadarElementDetected)
	local instance = self:superClass():create(dcsRadarTarget.object)
	setmetatable(instance, self)
	self.__index = self
	instance.abstractRadarElementsDetected = {}
	table.insert(instance.abstractRadarElementsDetected, abstractRadarElementDetected)
	instance.firstContactTime = timer.getAbsTime()
	instance.lastTimeSeen = 0
	instance.dcsRadarTarget = dcsRadarTarget
	instance.position = instance:getDCSRepresentation():getPosition()
	instance.numOfTimesRefreshed = 0
	instance.speed = 0
	instance.harmState = SkynetIADSContact.HARM_UNKNOWN
	instance.simpleAltitudeProfile = {}
	return instance
end

function SkynetIADSContact:setHARMState(state)
	self.harmState = state
end

function SkynetIADSContact:getHARMState()
	return self.harmState
end

function SkynetIADSContact:isIdentifiedAsHARM()
	return self.harmState == SkynetIADSContact.HARM
end

function SkynetIADSContact:isHARMStateUnknown()
	return self.harmState == SkynetIADSContact.HARM_UNKNOWN
end

function SkynetIADSContact:getMagneticHeading()
	if ( self:isExist() ) then
		return mist.utils.round(mist.utils.toDegree(mist.getHeading(self:getDCSRepresentation())))
	else
		return -1
	end
end

function SkynetIADSContact:getAbstractRadarElementsDetected()
	return self.abstractRadarElementsDetected
end

function SkynetIADSContact:addAbstractRadarElementDetected(radar)
	self:insertToTableIfNotAlreadyAdded(self.abstractRadarElementsDetected, radar)
end

function SkynetIADSContact:isTypeKnown()
	return self.dcsRadarTarget.type
end

function SkynetIADSContact:isDistanceKnown()
	return self.dcsRadarTarget.distance
end

function SkynetIADSContact:getTypeName()
	if self:isIdentifiedAsHARM() then
		return SkynetIADSContact.HARM
	end
	if self:getDCSRepresentation() ~= nil then
		local category = self:getDCSRepresentation():getCategory()
		if category == Object.Category.UNIT then
			return self.typeName
		end
	end
	return "UNKNOWN"
end

function SkynetIADSContact:getPosition()
	return self.position
end

function SkynetIADSContact:getGroundSpeedInKnots(decimals)
	if decimals == nil then
		decimals = 2
	end
	return mist.utils.round(self.speed, decimals)
end

function SkynetIADSContact:getHeightInFeetMSL()
	if self:isExist() then
		return mist.utils.round(mist.utils.metersToFeet(self:getDCSRepresentation():getPosition().p.y), 0)
	else
		return 0
	end
end

function SkynetIADSContact:getDesc()
	if self:isExist() then
		return self:getDCSRepresentation():getDesc()
	else
		return {}
	end
end

function SkynetIADSContact:getNumberOfTimesHitByRadar()
	return self.numOfTimesRefreshed
end

function SkynetIADSContact:refresh()
	if self:isExist() then
		local timeDelta = (timer.getAbsTime() - self.lastTimeSeen)
		if timeDelta > 0 then
			self.numOfTimesRefreshed = self.numOfTimesRefreshed + 1
			local distance = mist.utils.metersToNM(mist.utils.get2DDist(self.position.p, self:getDCSRepresentation():getPosition().p))
			local hours = timeDelta / 3600
			self.speed = (distance / hours)
			self:updateSimpleAltitudeProfile()
			self.position = self:getDCSRepresentation():getPosition()
		end 
	end
	self.lastTimeSeen = timer.getAbsTime()
end

function SkynetIADSContact:updateSimpleAltitudeProfile()
	local currentAltitude = self:getDCSRepresentation():getPosition().p.y
	
	local previousPath = ""
	if #self.simpleAltitudeProfile > 0 then
		previousPath = self.simpleAltitudeProfile[#self.simpleAltitudeProfile]
	end
	
	if self.position.p.y > currentAltitude and previousPath ~= SkynetIADSContact.DESCEND then
		table.insert(self.simpleAltitudeProfile, SkynetIADSContact.DESCEND)
	elseif self.position.p.y < currentAltitude and previousPath ~= SkynetIADSContact.CLIMB then
		table.insert(self.simpleAltitudeProfile, SkynetIADSContact.CLIMB)
	end
end

function SkynetIADSContact:getSimpleAltitudeProfile()
	return self.simpleAltitudeProfile
end

function SkynetIADSContact:getAge()
	return mist.utils.round(timer.getAbsTime() - self.lastTimeSeen)
end

end

do

SkynetIADSEWRadar = {}
SkynetIADSEWRadar = inheritsFrom(SkynetIADSAbstractRadarElement)

function SkynetIADSEWRadar:create(radarUnit, iads)
	local instance = self:superClass():create(radarUnit, iads)
	setmetatable(instance, self)
	self.__index = self
	instance.autonomousBehaviour = SkynetIADSAbstractRadarElement.AUTONOMOUS_STATE_DARK
	return instance
end

function SkynetIADSEWRadar:setupElements()
	local unit = self:getDCSRepresentation()
	local unitType = unit:getTypeName()
	for typeName, dataType in pairs(SkynetIADS.database) do
		for entry, unitData in pairs(dataType) do
			if entry == 'searchRadar' then
				--buildSingleUnit checks to make sure the EW radar is defined in the Skynet database. If it is not, self.searchRadars will be 0 so no ew radar will be added
				self:buildSingleUnit(unit, SkynetIADSSAMSearchRadar, self.searchRadars, unitData)
				if #self.searchRadars > 0 then
					local harmDetection = dataType['harm_detection_chance']
					self:setHARMDetectionChance(harmDetection)
					if unitData[unitType]['name'] then
						local natoName = unitData[unitType]['name']['NATO']
						self:buildNatoName(natoName)
					end
					return
				end
			end
		end
	end
end

--an Early Warning Radar has simplified check to determine if its autonomous or not
function SkynetIADSEWRadar:setToCorrectAutonomousState()
	if self:hasActiveConnectionNode() and self:hasWorkingPowerSource() and self.iads:isCommandCenterUsable() then
		self:resetAutonomousState()
		self:goLive()
	end
	if self:hasActiveConnectionNode() == false or self.iads:isCommandCenterUsable() == false then
		self:goAutonomous()
	end
end

end
do

SkynetIADSJammer = {}
SkynetIADSJammer.__index = SkynetIADSJammer

function SkynetIADSJammer:create(emitter, iads)
	local jammer = {}
	setmetatable(jammer, SkynetIADSJammer)
	jammer.radioMenu = nil
	jammer.emitter = emitter
	jammer.jammerTaskID = nil
	jammer.iads = {iads}
	jammer.maximumEffectiveDistanceNM = 200
	--jammer probability settings are stored here, visualisation, see: https://docs.google.com/spreadsheets/d/16rnaU49ZpOczPEsdGJ6nfD0SLPxYLEYKmmo4i2Vfoe0/edit#gid=0
	jammer.jammerTable = {
		['SA-2'] = {
			['function'] = function(distanceNauticalMiles) return ( 1.4 ^ distanceNauticalMiles ) + 90 end,
			['canjam'] = true,
		},
		['SA-3'] = {
			['function'] = function(distanceNauticalMiles) return ( 1.4 ^ distanceNauticalMiles ) + 80 end,
			['canjam'] = true,
		},
		['SA-6'] = {
			['function'] = function(distanceNauticalMiles) return ( 1.4 ^ distanceNauticalMiles ) + 23 end,
			['canjam'] = true,
		},
		['SA-8'] = {
			['function'] = function(distanceNauticalMiles) return ( 1.35 ^ distanceNauticalMiles ) + 30 end,
			['canjam'] = true,
		},
		['SA-10'] = {
			['function'] = function(distanceNauticalMiles) return ( 1.07 ^ (distanceNauticalMiles / 1.13) ) + 5 end,
			['canjam'] = true,
		},
		['SA-11'] = {
			['function'] = function(distanceNauticalMiles) return ( 1.25 ^ distanceNauticalMiles ) + 15 end,
			['canjam'] = true,
		},
		['SA-15'] = {
			['function'] = function(distanceNauticalMiles) return ( 1.15 ^ distanceNauticalMiles ) + 5 end,
			['canjam'] = true,
		},
	}
	return jammer
end

function SkynetIADSJammer:masterArmOn()
	self:masterArmSafe()
	self.jammerTaskID = mist.scheduleFunction(SkynetIADSJammer.runCycle, {self}, 1, 2)
end

function SkynetIADSJammer:addFunction(natoName, jammerFunction)
	self.jammerTable[natoName] = {
		['function'] = jammerFunction,
		['canjam'] = true
	}
end

function SkynetIADSJammer:setMaximumEffectiveDistance(distance)
	self.maximumEffectiveDistanceNM = distance
end

function SkynetIADSJammer:disableFor(natoName)
	self.jammerTable[natoName]['canjam'] = false
end

function SkynetIADSJammer:isKnownRadarEmitter(natoName)
	local isActive = false
	for unitName, unit in pairs(self.jammerTable) do
		if unitName == natoName and unit['canjam'] == true then
			isActive = true
		end
	end
	return isActive
end

function SkynetIADSJammer:addIADS(iads)
	table.insert(self.iads, iads)
end

function SkynetIADSJammer:getSuccessProbability(distanceNauticalMiles, natoName)
	local probability = 0
	local jammerSettings = self.jammerTable[natoName]
	if jammerSettings ~= nil then
		probability = jammerSettings['function'](distanceNauticalMiles)
	end
	return probability
end

function SkynetIADSJammer:getDistanceNMToRadarUnit(radarUnit)
	return mist.utils.metersToNM(mist.utils.get3DDist(self.emitter:getPosition().p, radarUnit:getPosition().p))
end

function SkynetIADSJammer:applyEA18GBridge(iads, samSite)
	if EA18GSkynetJammerBridge and EA18GSkynetJammerBridge.getSuccessProbability then
		local handled, successProbability = EA18GSkynetJammerBridge.getSuccessProbability(self.emitter, samSite, iads, self)
		if handled then
			if successProbability ~= nil then
				samSite:jam(successProbability)
			end
			return true
		end
	end
	return false
end

function SkynetIADSJammer.runCycle(self)

	if self.emitter:isExist() == false then
		self:masterArmSafe()
		return
	end

	for i = 1, #self.iads do
		local iads = self.iads[i]
		local samSites = iads:getActiveSAMSites()	
		for j = 1, #samSites do
			local samSite = samSites[j]
			local handledByEA18G = self:applyEA18GBridge(iads, samSite)
			if handledByEA18G == false then
				local radars = samSite:getRadars()
				local distance = 0
				local natoName = samSite:getNatoName()
				for l = 1, #radars do
					local radar = radars[l]
					distance = self:getDistanceNMToRadarUnit(radar)
					-- I try to emulate the system as it would work in real life, so a jammer can only jam a SAM site if has line of sight to at least one radar in the group
					if self:isKnownRadarEmitter(natoName) and self:hasLineOfSightToRadar(radar) and distance <= self.maximumEffectiveDistanceNM then
						if iads:getDebugSettings().jammerProbability then
							iads:printOutput("JAMMER: Distance: "..distance)
						end
						samSite:jam(self:getSuccessProbability(distance, natoName))
					end
				end
			end
		end
	end
end

function SkynetIADSJammer:hasLineOfSightToRadar(radar)
	local radarPos = radar:getPosition().p
	--lift the radar 30 meters off the ground, some 3d models are dug in to the ground, creating issues in calculating LOS
	radarPos.y = radarPos.y + 30
	return land.isVisible(radarPos, self.emitter:getPosition().p) 
end

function SkynetIADSJammer:masterArmSafe()
	mist.removeFunction(self.jammerTaskID)
end

--TODO: Remove Menu when emitter dies:
function SkynetIADSJammer:addRadioMenu()
	self.radioMenu = missionCommands.addSubMenu('Jammer: '..self.emitter:getName())
	missionCommands.addCommand('Master Arm On', self.radioMenu, SkynetIADSJammer.updateMasterArm, {self = self, option = 'masterArmOn'})
	missionCommands.addCommand('Master Arm Safe', self.radioMenu, SkynetIADSJammer.updateMasterArm, {self = self, option = 'masterArmSafe'})
end

function SkynetIADSJammer.updateMasterArm(params)
	local option = params.option
	local self = params.self
	if option == 'masterArmOn' then
		self:masterArmOn()
	elseif option == 'masterArmSafe' then
		self:masterArmSafe()
	end
end

function SkynetIADSJammer:removeRadioMenu()
	missionCommands.removeItem(self.radioMenu)
end

end
do

SkynetIADSSAMSearchRadar = {}
SkynetIADSSAMSearchRadar = inheritsFrom(SkynetIADSAbstractDCSObjectWrapper)

function SkynetIADSSAMSearchRadar:create(unit)
	local instance = self:superClass():create(unit)
	setmetatable(instance, self)
	self.__index = self
	instance.firingRangePercent = 100
	instance.maximumRange = 0
	instance.initialNumberOfMissiles = 0
	instance.remainingNumberOfMissiles = 0
	instance.initialNumberOfShells = 0
	instance.remainingNumberOfShells = 0
	instance.triedSensors = 0
	return instance
end

--override in subclasses to match different datastructure of getSensors()
function SkynetIADSSAMSearchRadar:setupRangeData()
	if self:isExist() then
		local data = self:getDCSRepresentation():getSensors()
		if data == nil then
			--this is to prevent infinite calls between launcher and search radar
			self.triedSensors = self.triedSensors + 1
			--the SA-13 does not have any sensor data, but is has launcher data, so we use the stuff from the launcher for the radar range.
			SkynetIADSSAMLauncher.setupRangeData(self)
			return
		end
		for i = 1, #data do
			local subEntries = data[i]
			for j = 1, #subEntries do
				local sensorInformation = subEntries[j]
				-- some sam sites have  IR and passive EWR detection, we are just interested in the radar data
				-- investigate if upperHemisphere and headOn is ok, I guess it will work for most detection cases
				if sensorInformation.type == Unit.SensorType.RADAR and sensorInformation['detectionDistanceAir'] then
					local upperHemisphere = sensorInformation['detectionDistanceAir']['upperHemisphere']['headOn']
					local lowerHemisphere = sensorInformation['detectionDistanceAir']['lowerHemisphere']['headOn']
					self.maximumRange = upperHemisphere
					if lowerHemisphere > upperHemisphere then
						self.maximumRange = lowerHemisphere
					end
				end
			end
		end
	end
end

function SkynetIADSSAMSearchRadar:getMaxRangeFindingTarget()
	return self.maximumRange
end

function SkynetIADSSAMSearchRadar:isRadarWorking()
	-- the ammo check is for the SA-13 which does not return any sensor data:
	return (self:isExist() == true and ( self:getDCSRepresentation():getSensors() ~= nil or self:getDCSRepresentation():getAmmo() ~= nil ) )
end

function SkynetIADSSAMSearchRadar:setFiringRangePercent(percent)
	self.firingRangePercent = percent
end

function SkynetIADSSAMSearchRadar:getDistance(target)
	return mist.utils.get2DDist(target:getPosition().p, self:getDCSRepresentation():getPosition().p)
end

function SkynetIADSSAMSearchRadar:getHeight(target)
	local radarElevation = self:getDCSRepresentation():getPosition().p.y
	local targetElevation = target:getPosition().p.y
	return math.abs(targetElevation - radarElevation)
end

function SkynetIADSSAMSearchRadar:isInHorizontalRange(target)
	return (self:getMaxRangeFindingTarget() / 100 * self.firingRangePercent) >= self:getDistance(target)
end

function SkynetIADSSAMSearchRadar:isInRange(target)
	if self:isExist() == false then
		return false
	end
	return self:isInHorizontalRange(target)
end

end

do

SkynetIADSSamSite = {}
SkynetIADSSamSite = inheritsFrom(SkynetIADSAbstractRadarElement)

function SkynetIADSSamSite:create(samGroup, iads)
	local sam = self:superClass():create(samGroup, iads)
	setmetatable(sam, self)
	self.__index = self
	sam.targetsInRange = false
	sam.goLiveConstraints = {}
	return sam
end

function SkynetIADSSamSite:addGoLiveConstraint(constraintName, constraint)
	self.goLiveConstraints[constraintName] = constraint
end

function SkynetIADSAbstractRadarElement:areGoLiveConstraintsSatisfied(contact)
	for constraintName, constraint in pairs(self.goLiveConstraints) do
		if ( constraint(contact) ~= true ) then
			return false
		end
	end
	return true
end

function SkynetIADSAbstractRadarElement:removeGoLiveConstraint(constraintName)
	local constraints = {}
	for cName, constraint in pairs(self.goLiveConstraints) do
		if cName ~= constraintName then
			constraints[cName] = constraint
		end
	end
	self.goLiveConstraints = constraints
end

function SkynetIADSAbstractRadarElement:getGoLiveConstraints()
	return self.goLiveConstraints
end

function SkynetIADSSamSite:isDestroyed()
	local isDestroyed = true
	for i = 1, #self.launchers do
		local launcher = self.launchers[i]
		if launcher:isExist() == true then
			isDestroyed = false
		end
	end
	local radars = self:getRadars()
	for i = 1, #radars do
		local radar = radars[i]
		if radar:isExist() == true then
			isDestroyed = false
		end
	end	
	return isDestroyed
end

function SkynetIADSSamSite:targetCycleUpdateStart()
	self.targetsInRange = false
end

function SkynetIADSSamSite:targetCycleUpdateEnd()
	if self.targetsInRange == false and self.actAsEW == false and self:getAutonomousState() == false and self:getAutonomousBehaviour() == SkynetIADSAbstractRadarElement.AUTONOMOUS_STATE_DCS_AI then
		self:goDark()
	end
end

function SkynetIADSSamSite:informOfContact(contact)
	-- we make sure isTargetInRange (expensive call) is only triggered if no previous calls to this method resulted in targets in range
	if ( self.targetsInRange == false and self:areGoLiveConstraintsSatisfied(contact) == true and self:isTargetInRange(contact) and ( contact:isIdentifiedAsHARM() == false or ( contact:isIdentifiedAsHARM() == true and self:getCanEngageHARM() == true ) ) ) then
		self:goLive()
		self.targetsInRange = true
	end
end

end
do

SkynetIADSSAMTrackingRadar = {}
SkynetIADSSAMTrackingRadar = inheritsFrom(SkynetIADSSAMSearchRadar)

function SkynetIADSSAMTrackingRadar:create(unit)
	local instance = self:superClass():create(unit)
	setmetatable(instance, self)
	self.__index = self
	return instance
end

end
do

SkynetIADSSAMLauncher = {}
SkynetIADSSAMLauncher = inheritsFrom(SkynetIADSSAMSearchRadar)

function SkynetIADSSAMLauncher:create(unit)
	local instance = self:superClass():create(unit)
	setmetatable(instance, self)
	self.__index = self
	instance.maximumFiringAltitude = 0
	return instance
end

function SkynetIADSSAMLauncher:setupRangeData()
	self.remainingNumberOfMissiles = 0
	self.remainingNumberOfShells = 0
	if self:isExist() then
		local data = self:getDCSRepresentation():getAmmo()
		local initialNumberOfMissiles = 0
		local initialNumberOfShells = 0
		--data becomes nil, when all missiles are fired
		if data then
			for i = 1, #data do
				local ammo = data[i]		
				--we ignore checks on radar guidance types, since we are not interested in how exactly the missile is guided by the SAM site.
				if ammo.desc.category == Weapon.Category.MISSILE then
					--TODO: see what the difference is between Max and Min values, SA-3 has higher Min value than Max?, most likely it has to do with the box parameters supplied by launcher
					--to simplyfy we just use the larger value, sam sites need a few seconds of tracking time to fire, by that time contact has most likely closed in on the SAM site.
					local altMin = ammo.desc.rangeMaxAltMin
					local altMax = ammo.desc.rangeMaxAltMax
					self.maximumRange = altMin
					if altMin < altMax then
						self.maximumRange = altMax
					end
					self.maximumFiringAltitude = ammo.desc.altMax
					self.remainingNumberOfMissiles = self.remainingNumberOfMissiles + ammo.count
					initialNumberOfMissiles = self.remainingNumberOfMissiles
				end
				if ammo.desc.category == Weapon.Category.SHELL then
					self.remainingNumberOfShells = self.remainingNumberOfShells + ammo.count
					initialNumberOfShells = self.remainingNumberOfShells
				end
				--if no distance was detected we run the code for the search radar. This happens when all in one units are passed like the shilka
				if self.maximumRange == 0 then
					--this is to prevent infinite calls between launcher and search radar
					if self.triedSensors <= 2 then
						SkynetIADSSAMSearchRadar.setupRangeData(self)
					end
				end
			end
			-- conditions here are because setupRangeData() is called multiple times in the code to update ammo status, we set initial values only the first time the method is called
			if self.initialNumberOfMissiles == 0 then
				self.initialNumberOfMissiles = initialNumberOfMissiles
			end
			if self.initialNumberOfShells == 0 then
				self.initialNumberOfShells = initialNumberOfShells
			end
		end
	end
end

function SkynetIADSSAMLauncher:getInitialNumberOfShells()
	return self.initialNumberOfShells
end

function SkynetIADSSAMLauncher:getRemainingNumberOfShells()
	self:setupRangeData()
	return self.remainingNumberOfShells
end

function SkynetIADSSAMLauncher:getInitialNumberOfMissiles()
	return self.initialNumberOfMissiles
end

function SkynetIADSSAMLauncher:getRemainingNumberOfMissiles()
	self:setupRangeData()
	return self.remainingNumberOfMissiles
end

function SkynetIADSSAMLauncher:getRange()
	return self.maximumRange
end

function SkynetIADSSAMLauncher:getMaximumFiringAltitude()
	return self.maximumFiringAltitude
end

function SkynetIADSSAMLauncher:isWithinFiringHeight(target)
	-- if no max firing height is set (radar quided AAA) then we use the vertical range, bit of a hack but probably ok for AAA
	if self:getMaximumFiringAltitude() > 0 then
		return self:getMaximumFiringAltitude() >= self:getHeight(target) 
	else
		return self:getRange() >= self:getHeight(target)
	end
end

function SkynetIADSSAMLauncher:isInRange(target)
	if self:isExist() == false then
		return false
	end
	return self:isWithinFiringHeight(target) and self:isInHorizontalRange(target)
end

function SkynetIADSSAMLauncher:canProvideRadarCoverage()
	if self:isExist() == false then
		return false
	end

	local okSensors, sensors = pcall(function()
		return self:getDCSRepresentation():getSensors()
	end)

	return okSensors and sensors ~= nil
end

end

--[[
SA-2 Launcher:
    {
        count=1,
        desc={
            Nmax=17,
            RCS=0.39669999480247,
            _origin="",
            altMax=25000,
            altMin=100,
            box={
                max={x=4.7303376197815, y=0.84564626216888, z=0.84564626216888},
                min={x=-5.8387970924377, y=-0.84564626216888, z=-0.84564626216888}
            },
            category=1,
            displayName="SA2V755",
            fuseDist=20,
            guidance=4,
            life=2,
            missileCategory=2,
            rangeMaxAltMax=30000,
            rangeMaxAltMin=40000,
            rangeMin=7000,
            typeName="SA2V755",
            warhead={caliber=500, explosiveMass=196, mass=196, type=1}
        }
    }
}
--]]
do

SkynetIADSHARMDetection = {}
SkynetIADSHARMDetection.__index = SkynetIADSHARMDetection

SkynetIADSHARMDetection.HARM_THRESHOLD_SPEED_KTS = 400

function SkynetIADSHARMDetection:create(iads)
	local harmDetection = {}
	setmetatable(harmDetection, self)
	harmDetection.contacts = {}
	harmDetection.iads = iads
	harmDetection.contactRadarsEvaluated = {}
	return harmDetection
end

function SkynetIADSHARMDetection:setContacts(contacts)
	self.contacts = contacts
end

function SkynetIADSHARMDetection:getDirectTargetElement(contact)
	local representation = nil
	local okRepresentation = pcall(function()
		representation = contact.getDCSRepresentation and contact:getDCSRepresentation() or nil
	end)
	if okRepresentation ~= true or representation == nil or representation.getTarget == nil then
		return nil
	end

	local target = nil
	local okTarget = pcall(function()
		target = representation:getTarget()
	end)
	if okTarget ~= true or target == nil then
		return nil
	end

	local group = nil
	local okGroup = pcall(function()
		group = target.getGroup and target:getGroup() or nil
	end)
	if okGroup == true and group and group.getName then
		local okGroupName, groupName = pcall(function()
			return group:getName()
		end)
		if okGroupName and groupName then
			local samSite = self.iads:getSAMSiteByGroupName(groupName)
			if samSite then
				return samSite
			end
		end
	end

	local targetName = nil
	local okTargetName = pcall(function()
		targetName = target.getName and target:getName() or nil
	end)
	if okTargetName == true and targetName then
		local ewRadar = self.iads:getEarlyWarningRadarByUnitName(targetName)
		if ewRadar then
			return ewRadar
		end
	end

	return nil
end

function SkynetIADSHARMDetection:evaluateContacts()
	self:cleanAgedContacts()
	for i = 1, #self.contacts do
		local contact = self.contacts[i]
		local directTargetElement = self:getDirectTargetElement(contact)
		local hasDirectTarget = directTargetElement ~= nil
		if hasDirectTarget then
			contact._skynetDirectTargetGroupName = directTargetElement:getDCSName()
			contact:setHARMState(SkynetIADSContact.HARM)
		else
			contact._skynetDirectTargetGroupName = nil
		end
		local groundSpeed  = contact:getGroundSpeedInKnots(0)
		--if a contact has only been hit by a radar once it's speed is 0
		--如果接触只被雷达击中一次，其速度为0
		if groundSpeed == 0 then
			-- Ignore this incomplete contact and continue evaluating the rest.
		end
		local simpleAltitudeProfile = contact:getSimpleAltitudeProfile()
		local newRadarsToEvaluate = self:getNewRadarsThatHaveDetectedContact(contact)
		--self.iads:printOutputToLog(contact:getName().." new Radars to evaluate: "..#newRadarsToEvaluate)
		--self.iads:printOutputToLog(contact:getName().." ground speed: "..groundSpeed)
		--self.iads:printOutputToLog(contact:getName().." 要评估的新雷达："..#newRadarsToEvaluate)
		--self.iads:printOutputToLog(contact:getName().." 地面速度："..groundSpeed)
		if ( hasDirectTarget == false and #newRadarsToEvaluate > 0 and contact:isIdentifiedAsHARM() == false and ( groundSpeed > SkynetIADSHARMDetection.HARM_THRESHOLD_SPEED_KTS and #simpleAltitudeProfile <= 2 ) ) then
			local detectionProbability = self:getDetectionProbability(newRadarsToEvaluate)
			--self.iads:printOutputToLog("DETECTION PROB: "..detectionProbability)
			--self.iads:printOutputToLog("检测概率："..detectionProbability)
			if ( self:shallReactToHARM(detectionProbability) ) then
				contact:setHARMState(SkynetIADSContact.HARM)
				if (self.iads:getDebugSettings().harmDefence ) then
					self.iads:printOutputToLog("HARM IDENTIFIED: "..contact:getTypeName().." | DETECTION PROBABILITY WAS: "..detectionProbability.."%")
				end
			else
				contact:setHARMState(SkynetIADSContact.NOT_HARM)
				if (self.iads:getDebugSettings().harmDefence ) then
					self.iads:printOutputToLog("HARM NOT IDENTIFIED: "..contact:getTypeName().." | DETECTION PROBABILITY WAS: "..detectionProbability.."%")
				end
			end
		end
		
		if ( hasDirectTarget == false and #simpleAltitudeProfile > 2 and contact:isIdentifiedAsHARM() ) then
			contact:setHARMState(SkynetIADSContact.HARM_UNKNOWN)
			if (self.iads:getDebugSettings().harmDefence ) then
				self.iads:printOutputToLog("CORRECTING HARM STATE: CONTACT IS NOT A HARM: "..contact:getName())
			end
		end
		
		if ( contact:isIdentifiedAsHARM() ) then
			self:informRadarsOfHARM(contact)
		end
	end
end

function SkynetIADSHARMDetection:cleanAgedContacts()
	local activeContactRadars = {}
	for contact, radars in pairs (self.contactRadarsEvaluated) do
		if contact:getAge() < 32 then
			activeContactRadars[contact] = radars
		end
	end
	self.contactRadarsEvaluated = activeContactRadars
end

function SkynetIADSHARMDetection:getNewRadarsThatHaveDetectedContact(contact)
	local radarsFromContact = contact:getAbstractRadarElementsDetected()
	local evaluatedRadars = self.contactRadarsEvaluated[contact]
	local newRadars = {}
	if evaluatedRadars == nil then
		evaluatedRadars = {}
		self.contactRadarsEvaluated[contact] = evaluatedRadars
	end
	for i = 1, #radarsFromContact do
		local contactRadar = radarsFromContact[i]
		if self:isElementInTable(evaluatedRadars, contactRadar) == false then
			table.insert(evaluatedRadars, contactRadar)
			table.insert(newRadars, contactRadar)
		end
	end
	return newRadars
end

function SkynetIADSHARMDetection:isElementInTable(tbl, element)
	for i = 1, #tbl do
		local tblElement = tbl[i]
		if tblElement == element then
			return true
		end
	end
	return false
end

function SkynetIADSHARMDetection:informRadarsOfHARM(contact)
	local samSites = self.iads:getUsableSAMSites()
	self:updateRadarsOfSites(samSites, contact)
	
	local ewRadars = self.iads:getUsableEarlyWarningRadars()
	self:updateRadarsOfSites(ewRadars, contact)
end

function SkynetIADSHARMDetection:updateRadarsOfSites(sites, contact)
	for i = 1, #sites do
		local site = sites[i]
		site:informOfHARM(contact)
	end
end

function SkynetIADSHARMDetection:shallReactToHARM(chance)
	return chance >=  math.random(1, 100)
end

function SkynetIADSHARMDetection:getDetectionProbability(radars)
	local detectionChance = 0
	local missChance = 100
	local detection = 0
	for i = 1, #radars do
		detection = radars[i]:getHARMDetectionChance()
		if ( detectionChance == 0 ) then
			detectionChance = detection
		else
			detectionChance = detectionChance + (detection * (missChance / 100))
		end	
		missChance = 100 - detection
	end
	return detectionChance
end

end

do

SkynetIADSMobilePatrol = {}
SkynetIADSMobilePatrol.__index = SkynetIADSMobilePatrol

SkynetIADSMobilePatrol._hooksInstalled = false
SkynetIADSMobilePatrol._entriesByElement = setmetatable({}, { __mode = "k" })

SkynetIADSMobilePatrol.DEFAULT_CHECK_INTERVAL = 1
SkynetIADSMobilePatrol.DEFAULT_PATROL_SPEED_KMPH = 35
SkynetIADSMobilePatrol.DEFAULT_RESUME_DELAY_SECONDS = 30
SkynetIADSMobilePatrol.DEFAULT_RESUME_MULTIPLIER = 2
SkynetIADSMobilePatrol.DEFAULT_MSAM_RESUME_MULTIPLIER = 1.2
SkynetIADSMobilePatrol.DEFAULT_SA11_MSAM_ALERT_DISTANCE_NM = 25
SkynetIADSMobilePatrol.DEFAULT_SA11_MSAM_ENGAGE_DISTANCE_NM = 16
SkynetIADSMobilePatrol.DEFAULT_COMBAT_EXIT_NO_TARGET_SECONDS = 10
SkynetIADSMobilePatrol.DEFAULT_POST_COMBAT_MOBILE_SECONDS = 30
SkynetIADSMobilePatrol.DEFAULT_ARRIVAL_TOLERANCE_METERS = 60
SkynetIADSMobilePatrol.DEFAULT_ROUTE_REISSUE_SECONDS = 8
SkynetIADSMobilePatrol.DEFAULT_MIN_MOVEMENT_METERS = 25
SkynetIADSMobilePatrol.DEFAULT_PATROL_REFRESH_DELAYS = { 3, 10 }
SkynetIADSMobilePatrol.DEFAULT_DEPLOY_SCATTER_DISTANCE_METERS = 100
SkynetIADSMobilePatrol.DEFAULT_DEPLOY_SCATTER_FORM = "Diamond"
SkynetIADSMobilePatrol.DEFAULT_DEPLOY_SCATTER_CHECK_INTERVAL_SECONDS = 1
SkynetIADSMobilePatrol.DEFAULT_DEPLOY_SCATTER_MIN_COMPLETION_METERS = 60
SkynetIADSMobilePatrol.DEFAULT_PATROL_FORMATION_INTERVAL_METERS = 20
SkynetIADSMobilePatrol.DEFAULT_DEPLOY_FORMATION_INTERVAL_METERS = 100
SkynetIADSMobilePatrol.DEFAULT_MOVE_FIRE_NATO_NAMES = {
	["SA-8 Gecko"] = true,
	["SA-15 Gauntlet"] = true,
	["SA-19 Grison"] = true,
	["Gepard"] = true,
	["Zues"] = true,
}
SkynetIADSMobilePatrol.DEFAULT_MOVE_FIRE_LAUNCHER_TYPE_NAMES = {
	["Osa 9A33 ln"] = true,
	["Tor 9A331"] = true,
	["2S6 Tunguska"] = true,
	["Gepard"] = true,
	["ZSU-23-4 Shilka"] = true,
}

local function startsWith(value, prefix)
	return value and prefix and string.find(value, prefix, 1, true) == 1
end

local getGroupNameFromElement

local function groupHasUnitWithPrefix(group, prefix)
	if group == nil or group:isExist() == false then
		return false
	end
	local okUnits, units = pcall(function()
		return group:getUnits()
	end)
	if okUnits and units then
		for i = 1, #units do
			local unit = units[i]
			if unit and unit:isExist() and startsWith(unit:getName(), prefix) then
				return true
			end
		end
	end
	return false
end

local function samSiteMatchesPrefix(samSite, prefix)
	if startsWith(samSite:getDCSName(), prefix) then
		return true
	end
	local group = samSite:getDCSRepresentation()
	return groupHasUnitWithPrefix(group, prefix)
end

local function ewRadarMatchesPrefix(ewRadar, prefix)
	if startsWith(ewRadar:getDCSName(), prefix) then
		return true
	end
	local groupName = getGroupNameFromElement(ewRadar)
	if groupName == nil then
		return false
	end
	local group = Group.getByName(groupName)
	return groupHasUnitWithPrefix(group, prefix)
end

local function normalizeVec3(point)
	if point == nil or point.x == nil then
		return nil
	end
	local z = point.z or point.y
	if z == nil then
		return nil
	end
	local y = point.z and point.y or land.getHeight({ x = point.x, y = z })
	return {
		x = point.x,
		y = y or 0,
		z = z,
	}
end

local function appendNormalizedRoutePoints(routePoints, rawPoints)
	if rawPoints == nil then
		return
	end
	for i = 1, #rawPoints do
		local rawPoint = rawPoints[i]
		if rawPoint and rawPoint.point then
			rawPoint = rawPoint.point
		end
		local point = normalizeVec3(rawPoint)
		if point then
			routePoints[#routePoints + 1] = point
		end
	end
end

getGroupNameFromElement = function(element)
	local dcsRepresentation = element:getDCSRepresentation()
	if dcsRepresentation == nil or dcsRepresentation:isExist() == false then
		return nil
	end
	local okUnits, units = pcall(function()
		return dcsRepresentation:getUnits()
	end)
	if okUnits and units and #units > 0 then
		return dcsRepresentation:getName()
	end
	local okGroup, group = pcall(function()
		return dcsRepresentation:getGroup()
	end)
	if okGroup and group and group:isExist() then
		return group:getName()
	end
	return nil
end

local function getRoutePointsFromMissionGroup(groupName)
	local routePoints = {}
	local groupData = mist.DBs.groupsByName[groupName]
	if groupData and groupData.route and groupData.route.points then
		appendNormalizedRoutePoints(routePoints, groupData.route.points)
	end
	if #routePoints == 0 then
		local okRoute, route = pcall(function()
			return mist.getGroupRoute(groupName, true)
		end)
		if okRoute and route then
			appendNormalizedRoutePoints(routePoints, route)
		end
	end
	if #routePoints == 0 then
		local okPoints, points = pcall(function()
			return mist.getGroupPoints(groupName)
		end)
		if okPoints and points then
			appendNormalizedRoutePoints(routePoints, points)
		end
	end
	return routePoints
end

local function getLeadPointForGroup(group)
	local okPoint, point = pcall(function()
		return mist.getLeadPos(group)
	end)
	if okPoint then
		return point
	end
	return nil
end

local function getEnemyCoalition(coalitionId)
	if coalitionId == coalition.side.RED then
		return coalition.side.BLUE
	end
	if coalitionId == coalition.side.BLUE then
		return coalition.side.RED
	end
	return nil
end

local function collectEnemyAirUnits(enemyCoalitionId)
	local airUnits = {}
	if enemyCoalitionId == nil then
		return airUnits
	end
	local categories = {
		Group.Category.AIRPLANE,
		Group.Category.HELICOPTER,
	}
	for i = 1, #categories do
		local okGroups, groups = pcall(function()
			return coalition.getGroups(enemyCoalitionId, categories[i])
		end)
		if okGroups and groups then
			for j = 1, #groups do
				local group = groups[j]
				if group and group:isExist() then
					local units = group:getUnits()
					for k = 1, #units do
						local unit = units[k]
						if unit and unit:isExist() then
							airUnits[#airUnits + 1] = unit
						end
					end
				end
			end
		end
	end
	return airUnits
end

local function isAirContact(contact)
	if contact == nil or contact.getDesc == nil then
		return false
	end
	local representation = nil
	local okRepresentation = pcall(function()
		representation = contact.getDCSRepresentation and contact:getDCSRepresentation() or nil
	end)
	if okRepresentation ~= true or representation == nil then
		return false
	end
	if representation.isExist and representation:isExist() == false then
		return false
	end
	local categoryId = nil
	if representation.getCategory ~= nil then
		local okCategory, resolvedCategoryId = pcall(function()
			return representation:getCategory()
		end)
		if okCategory ~= true then
			return false
		end
		categoryId = resolvedCategoryId
	end
	if categoryId ~= nil and categoryId ~= Object.Category.UNIT then
		return false
	end
	local okDesc, desc = pcall(function()
		return contact:getDesc() or {}
	end)
	if okDesc ~= true then
		return false
	end
	local category = desc.category
	return category == Unit.Category.AIRPLANE or category == Unit.Category.HELICOPTER
end

local function setPatrolAlarmState(controller)
	pcall(function()
		controller:setOption(AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.GREEN)
	end)
end

local function setCombatAlarmState(controller)
	pcall(function()
		controller:setOption(AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.RED)
	end)
end

local collectElementEmitterRepresentations

local function setGroundROE(controller, weaponHold)
	pcall(function()
		controller:setOption(
			AI.Option.Ground.id.ROE,
			weaponHold and AI.Option.Ground.val.ROE.WEAPON_HOLD or AI.Option.Ground.val.ROE.OPEN_FIRE
		)
	end)
end

local function setGroundFormationInterval(controller, meters)
	if controller == nil or meters == nil then
		return
	end
	local intervalMeters = math.max(0, math.min(100, math.floor(meters + 0.5)))
	pcall(function()
		controller:setOption(30, intervalMeters)
	end)
end

local function applyFormationIntervalToEntry(entry, meters)
	if entry == nil then
		return
	end
	local group = entry.group
	if group and group.isExist and group:isExist() then
		local okController, controller = pcall(function()
			return group:getController()
		end)
		if okController and controller then
			setGroundFormationInterval(controller, meters)
		end
	end
	local element = entry.element
	if element and element.getController then
		local okController, controller = pcall(function()
			return element:getController()
		end)
		if okController and controller then
			setGroundFormationInterval(controller, meters)
		end
	end
end

local function setPatrolROE(controller)
	setGroundROE(controller, true)
end

local function setCombatROEForRepresentation(representation, weaponHold)
	if representation == nil or representation.isExist == nil or representation:isExist() == false then
		return
	end
	local okController, controller = pcall(function()
		return representation:getController()
	end)
	if okController and controller then
		pcall(function()
			controller:setOnOff(true)
		end)
		setCombatAlarmState(controller)
		setGroundROE(controller, weaponHold)
		pcall(function()
			representation:enableEmission(true)
		end)
	end
end

local function setElementCombatROE(element, weaponHold)
	if element == nil or element.isDestroyed == nil or element:isDestroyed() then
		return
	end
	local representations = collectElementEmitterRepresentations(element)
	for i = 1, #representations do
		setCombatROEForRepresentation(representations[i], weaponHold)
	end
	local controller = element.getController and element:getController() or nil
	if controller then
		pcall(function()
			controller:setOnOff(true)
		end)
		setCombatAlarmState(controller)
		setGroundROE(controller, weaponHold)
	end
	if weaponHold then
		element.aiState = true
	end
end

local function setMovingCombatROEForRepresentation(representation, weaponHold)
	if representation == nil or representation.isExist == nil or representation:isExist() == false then
		return
	end
	local okController, controller = pcall(function()
		return representation:getController()
	end)
	if okController and controller then
		pcall(function()
			controller:setOnOff(true)
		end)
		setCombatAlarmState(controller)
		setGroundROE(controller, weaponHold)
		pcall(function()
			representation:enableEmission(true)
		end)
	end
end

local function setElementMovingCombatState(element, weaponHold)
	if element == nil or element.isDestroyed == nil or element:isDestroyed() then
		return
	end
	local representations = collectElementEmitterRepresentations(element)
	for i = 1, #representations do
		setMovingCombatROEForRepresentation(representations[i], weaponHold)
	end
	local controller = element.getController and element:getController() or nil
	if controller then
		pcall(function()
			controller:setOnOff(true)
		end)
		setCombatAlarmState(controller)
		setGroundROE(controller, weaponHold)
	end
	element.goLiveTime = timer.getTime()
	element.aiState = true
	if element.pointDefencesStopActingAsEW then
		element:pointDefencesStopActingAsEW()
	end
	if element.scanForHarms then
		element:scanForHarms()
	end
end

local function setElementMovingSilenceState(element)
	if element == nil or element.isDestroyed == nil or element:isDestroyed() then
		return
	end
	local representations = collectElementEmitterRepresentations(element)
	for i = 1, #representations do
		local representation = representations[i]
		pcall(function()
			representation:enableEmission(false)
		end)
		applyPatrolOptionsToRepresentation(representation)
	end
	local controller = element.getController and element:getController() or nil
	if controller then
		pcall(function()
			controller:setOnOff(true)
		end)
		setPatrolAlarmState(controller)
		setPatrolROE(controller)
	end
	element.aiState = false
	if element.targetsInRange ~= nil then
		element.targetsInRange = false
	end
	element.cachedTargets = {}
	if element.stopScanningForHARMs then
		element:stopScanningForHARMs()
	end
end

local function appendUniqueRepresentation(representations, representation, seenKeys)
	if representation == nil or representation.isExist == nil or representation:isExist() == false then
		return
	end
	local key = nil
	local okName, name = pcall(function()
		return representation:getName()
	end)
	if okName and name then
		key = name
	end
	if key == nil then
		key = tostring(representation)
	end
	if seenKeys[key] then
		return
	end
	seenKeys[key] = true
	representations[#representations + 1] = representation
end

collectElementEmitterRepresentations = function(element)
	local representations = {}
	local seenKeys = {}
	appendUniqueRepresentation(representations, element:getDCSRepresentation(), seenKeys)

	local searchRadars = element.getSearchRadars and element:getSearchRadars() or {}
	for i = 1, #searchRadars do
		appendUniqueRepresentation(representations, searchRadars[i]:getDCSRepresentation(), seenKeys)
	end

	local trackingRadars = element.getTrackingRadars and element:getTrackingRadars() or {}
	for i = 1, #trackingRadars do
		appendUniqueRepresentation(representations, trackingRadars[i]:getDCSRepresentation(), seenKeys)
	end

	local launchers = element.getLaunchers and element:getLaunchers() or {}
	for i = 1, #launchers do
		appendUniqueRepresentation(representations, launchers[i]:getDCSRepresentation(), seenKeys)
	end

	return representations
end

local function applyPatrolOptionsToRepresentation(representation)
	if representation == nil or representation.isExist == nil or representation:isExist() == false then
		return
	end
	local okController, controller = pcall(function()
		return representation:getController()
	end)
	if okController and controller then
		pcall(function()
			controller:setOnOff(true)
		end)
		setPatrolAlarmState(controller)
		setPatrolROE(controller)
	end
end

local function forceElementIntoPatrolDarkState(element)
	if element == nil or element.isDestroyed == nil or element:isDestroyed() then
		return
	end
	local representations = collectElementEmitterRepresentations(element)
	for i = 1, #representations do
		local representation = representations[i]
		pcall(function()
			representation:enableEmission(false)
		end)
		applyPatrolOptionsToRepresentation(representation)
	end
	local controller = element:getController and element:getController() or nil
	if controller then
		pcall(function()
			controller:setOnOff(true)
		end)
		setPatrolAlarmState(controller)
		setPatrolROE(controller)
	end
	element.aiState = false
	if element.targetsInRange ~= nil then
		element.targetsInRange = false
	end
	element.cachedTargets = {}
	if element.stopScanningForHARMs then
		element:stopScanningForHARMs()
	end
end

function SkynetIADSMobilePatrol.getEntryForElement(element)
	return SkynetIADSMobilePatrol._entriesByElement[element]
end

function SkynetIADSMobilePatrol:log(message)
	if self.iads then
		self.iads:printOutputToLog("[MobilePatrol] " .. message)
	end
end

function SkynetIADSMobilePatrol:notifyDebug(message)
	if _G.SkynetRuntimeDebugNotify and message then
		pcall(_G.SkynetRuntimeDebugNotify, message)
	end
end

function SkynetIADSMobilePatrol:announceCombatState(entry, threatDecision)
	if entry == nil or threatDecision == nil then
		return
	end
	local triggerInfo = threatDecision.triggerInfo or {}
	local targetName = triggerInfo.contactName or "unknown"
	local mode = threatDecision.combatMode or entry.combatMode or "default"
	local distanceDetails = ""
	if entry.combatCommitted == true and (mode == "combat_latched" or mode == "sibling_primary") then
		mode = "combat_committed"
		if entry.lastDeployTrigger and entry.lastDeployTrigger.contactName then
			targetName = entry.lastDeployTrigger.contactName
		end
		if entry.lastDeployTrigger then
			triggerInfo = entry.lastDeployTrigger
		end
	end
	local shouldGoLive = threatDecision.shouldGoLive == true
	local shouldWeaponHold = threatDecision.shouldWeaponHold == true
	local moveFireCapable = self:isMoveFireCapable(entry)
	if entry.kind == "MSAM" then
		local debugRangeMeters = self:getDeployTriggerRangeMeters(entry)
		if triggerInfo.engageRangeNm == nil then
			local combatRangeMeters = self:getCombatRangeMeters(entry)
			if combatRangeMeters and combatRangeMeters > 0 then
				triggerInfo.engageRangeNm = mist.utils.round(mist.utils.metersToNM(combatRangeMeters), 1)
			end
		end
		if triggerInfo.directDistanceNm == nil and debugRangeMeters and debugRangeMeters > 0 then
			local directUnit, directUnitDistanceMeters = self:findNearestEnemyAircraftUnit(entry, debugRangeMeters)
			if directUnit ~= nil and directUnitDistanceMeters < math.huge then
				triggerInfo.directDistanceNm = mist.utils.round(mist.utils.metersToNM(directUnitDistanceMeters), 1)
				if triggerInfo.contactName == nil or triggerInfo.contactName == "unknown" then
					local okDirectName, directName = pcall(function()
						return directUnit:getName()
					end)
					if okDirectName and directName then
						triggerInfo.contactName = directName
						targetName = directName
					end
				end
			end
		end
		if triggerInfo.distanceNm == nil and debugRangeMeters and debugRangeMeters > 0 then
			local debugContact, contactDistanceMeters = self:findNearestEligibleContact(entry, debugRangeMeters)
			if debugContact ~= nil and contactDistanceMeters < math.huge then
				triggerInfo.distanceNm = mist.utils.round(mist.utils.metersToNM(contactDistanceMeters), 1)
				if triggerInfo.contactName == nil or triggerInfo.contactName == "unknown" then
					triggerInfo.contactName = self:getContactName(debugContact)
					targetName = triggerInfo.contactName
				end
			end
		end
		if triggerInfo.effectiveDistanceNm == nil then
			triggerInfo.effectiveDistanceNm = triggerInfo.directDistanceNm or triggerInfo.distanceNm
		end
	end
	local announcementKey = table.concat({
		tostring(mode),
		tostring(shouldGoLive),
		tostring(shouldWeaponHold),
		tostring(targetName),
		tostring(moveFireCapable),
	}, "|")
	if entry.debugLastCombatAnnouncementKey == announcementKey then
		return
	end
	entry.debugLastCombatAnnouncementKey = announcementKey
	local action = moveFireCapable and "机动警戒" or "进入警戒模式"
	if shouldGoLive then
		if moveFireCapable then
			action = shouldWeaponHold and "机动锁定待射" or "机动交战"
		else
			action = shouldWeaponHold and "进入锁定待射" or "进入战斗模式"
		end
	end
	if triggerInfo.distanceNm ~= nil then
		distanceDetails = distanceDetails .. " | contact=" .. tostring(triggerInfo.distanceNm) .. "nm"
	end
	if triggerInfo.directDistanceNm ~= nil then
		distanceDetails = distanceDetails .. " | direct=" .. tostring(triggerInfo.directDistanceNm) .. "nm"
	end
	if triggerInfo.effectiveDistanceNm ~= nil then
		distanceDetails = distanceDetails .. " | effective=" .. tostring(triggerInfo.effectiveDistanceNm) .. "nm"
	end
	if triggerInfo.engageRangeNm ~= nil then
		distanceDetails = distanceDetails .. " | engage=" .. tostring(triggerInfo.engageRangeNm) .. "nm"
	end
	if triggerInfo.source ~= nil then
		distanceDetails = distanceDetails .. " | source=" .. tostring(triggerInfo.source)
	end
	self:notifyDebug(
		entry.groupName
		.. " "
		.. action
		.. " | mode="
		.. tostring(mode)
		.. " | target="
		.. tostring(targetName)
		.. distanceDetails
	)
end

function SkynetIADSMobilePatrol:registerEntryForElement(element, entry)
	self.entries[#self.entries + 1] = entry
	SkynetIADSMobilePatrol._entriesByElement[element] = entry
end

function SkynetIADSMobilePatrol:getPatrolReferencePoint(entry)
	local group = entry.group
	if group and group:isExist() then
		local point = getLeadPointForGroup(group)
		if point then
			return point
		end
	end
	local dcsRepresentation = entry.element:getDCSRepresentation()
	if dcsRepresentation and dcsRepresentation:isExist() then
		return dcsRepresentation:getPosition().p
	end
	return nil
end

function SkynetIADSMobilePatrol:getWaypointDistance(entry, point)
	local currentPoint = self:getPatrolReferencePoint(entry)
	if currentPoint == nil or point == nil then
		return math.huge
	end
	return mist.utils.get2DDist(currentPoint, point)
end

function SkynetIADSMobilePatrol:getPatrolForwardVector(entry)
	if entry == nil then
		return nil
	end
	local units = nil
	if entry.group and entry.group.isExist and entry.group:isExist() then
		local okUnits, groupUnits = pcall(function()
			return entry.group:getUnits()
		end)
		if okUnits and groupUnits then
			units = groupUnits
		end
	end
	if units then
		for i = 1, #units do
			local unit = units[i]
			if unit and unit.isExist and unit:isExist() then
				local okPos, position = pcall(function()
					return unit:getPosition()
				end)
				if okPos and position and position.x then
					return { x = position.x.x, z = position.x.z }
				end
			end
		end
	end
	local dcsRepresentation = entry.element and entry.element.getDCSRepresentation and entry.element:getDCSRepresentation() or nil
	if dcsRepresentation and dcsRepresentation.isExist and dcsRepresentation:isExist() then
		local okPos, position = pcall(function()
			return dcsRepresentation:getPosition()
		end)
		if okPos and position and position.x then
			return { x = position.x.x, z = position.x.z }
		end
	end
	return nil
end

function SkynetIADSMobilePatrol:isWaypointAhead(entry, point)
	local currentPoint = self:getPatrolReferencePoint(entry)
	local heading = self:getPatrolForwardVector(entry)
	if currentPoint == nil or point == nil or heading == nil then
		return nil
	end
	local vecX = point.x - currentPoint.x
	local vecZ = point.z - currentPoint.z
	local vecMag = math.sqrt((vecX * vecX) + (vecZ * vecZ))
	local headingMag = math.sqrt((heading.x * heading.x) + (heading.z * heading.z))
	if vecMag <= 1 or headingMag <= 0.001 then
		return nil
	end
	local dot = ((vecX / vecMag) * (heading.x / headingMag)) + ((vecZ / vecMag) * (heading.z / headingMag))
	return dot >= 0.15
end

function SkynetIADSMobilePatrol:selectStartingWaypointIndex(entry)
	if #entry.routePoints <= 1 then
		return 1
	end
	local nearestIndex = 1
	local nearestDistance = math.huge
	local nearestAheadIndex = nil
	local nearestAheadDistance = math.huge
	for i = 1, #entry.routePoints do
		local distance = self:getWaypointDistance(entry, entry.routePoints[i])
		if distance < nearestDistance then
			nearestDistance = distance
			nearestIndex = i
		end
		if self:isWaypointAhead(entry, entry.routePoints[i]) == true and distance < nearestAheadDistance then
			nearestAheadDistance = distance
			nearestAheadIndex = i
		end
	end
	if nearestAheadIndex ~= nil then
		if nearestAheadDistance <= entry.arrivalToleranceMeters then
			return (nearestAheadIndex % #entry.routePoints) + 1
		end
		return nearestAheadIndex
	end
	if nearestDistance <= entry.arrivalToleranceMeters then
		return (nearestIndex % #entry.routePoints) + 1
	end
	return nearestIndex
end

function SkynetIADSMobilePatrol:buildRoadPatrolRoute(entry, startIndex)
	if entry == nil or #entry.routePoints == 0 then
		return nil
	end
	local route = {}
	local speedMps = mist.utils.kmphToMps(entry.patrolSpeedKmph)
	for offset = 0, (#entry.routePoints - 1) do
		local index = ((startIndex - 1 + offset) % #entry.routePoints) + 1
		local point = entry.routePoints[index]
		if point then
			route[#route + 1] = mist.ground.buildWP(point, "On Road", speedMps)
		end
	end
	return #route > 0 and route or nil
end

function SkynetIADSMobilePatrol:issueRoadMove(entry, destination)
	if entry.group == nil or entry.group:isExist() == false or destination == nil then
		self:log("Road move skipped for "..tostring(entry.groupName).." | missing group or destination")
		return false
	end
	local startPoint = self:getPatrolReferencePoint(entry)
	if startPoint == nil then
		self:log("Road move skipped for "..tostring(entry.groupName).." | missing start point")
		return false
	end
	local ok = pcall(function()
		mist.goRoute(entry.group, {
			mist.ground.buildWP(startPoint, "On Road", mist.utils.kmphToMps(entry.patrolSpeedKmph)),
			mist.ground.buildWP(destination, "On Road", mist.utils.kmphToMps(entry.patrolSpeedKmph)),
		})
	end)
	if ok then
		entry.currentDestination = destination
		entry.lastRouteIssueTime = timer.getTime()
		entry.lastRouteIssueReferencePoint = startPoint
		self:log("Road move issued for "..entry.groupName.." | speed="..entry.patrolSpeedKmph.."km/h")
	else
		self:log("Road move failed for "..entry.groupName)
	end
	return ok
end

function SkynetIADSMobilePatrol:issuePatrolRoute(entry)
	if entry.group == nil or entry.group:isExist() == false then
		self:log("Patrol route skipped for "..tostring(entry.groupName).." | missing group")
		return false
	end
	local ok = pcall(function()
		mist.ground.patrolRoute({
			gpData = entry.groupName,
			useGroupRoute = entry.groupName,
			onRoadForm = "On Road",
			speed = mist.utils.kmphToMps(entry.patrolSpeedKmph),
		})
	end)
	if ok then
		entry.currentDestination = nil
		entry.lastRouteIssueTime = timer.getTime()
		entry.lastRouteIssueReferencePoint = self:getPatrolReferencePoint(entry)
		self:log("Patrol route issued for "..entry.groupName.." | speed="..entry.patrolSpeedKmph.."km/h")
	else
		self:log("Patrol route failed for "..entry.groupName)
	end
	return ok
end

function SkynetIADSMobilePatrol:shouldReissuePatrolRoute(entry)
	if entry.lastRouteIssueTime == nil or entry.lastRouteIssueReferencePoint == nil then
		return false
	end
	if (timer.getTime() - entry.lastRouteIssueTime) < self.defaultRouteReissueSeconds then
		return false
	end
	local currentPoint = self:getPatrolReferencePoint(entry)
	if currentPoint == nil then
		return false
	end
	local movedDistance = mist.utils.get2DDist(currentPoint, entry.lastRouteIssueReferencePoint)
	return movedDistance < self.defaultMinMovementMeters
end

function SkynetIADSMobilePatrol:issueHold(entry)
	local holdPoint = self:getPatrolReferencePoint(entry)
	if entry.group == nil or entry.group:isExist() == false or holdPoint == nil then
		return false
	end
	local ok = pcall(function()
		mist.goRoute(entry.group, {
			mist.ground.buildWP(holdPoint, "off_road", 0.1),
		})
	end)
	if ok then
		entry.currentDestination = nil
	end
	return ok
end

function SkynetIADSMobilePatrol:isDeployScatterPointOnLand(point)
	if point == nil then
		return false
	end
	if land == nil or land.getSurfaceType == nil or land.SurfaceType == nil or land.SurfaceType.LAND == nil then
		return true
	end
	local ok, surfaceType = pcall(function()
		return land.getSurfaceType({
			x = point.x,
			y = point.z
		})
	end)
	if ok ~= true then
		return true
	end
	return surfaceType == land.SurfaceType.LAND
end

function SkynetIADSMobilePatrol:calculateDeployScatterPoint(entry)
	local startPoint = self:getPatrolReferencePoint(entry)
	if startPoint == nil then
		return nil, 0, nil
	end
	local distanceMeters = SkynetIADSMobilePatrol.DEFAULT_DEPLOY_SCATTER_DISTANCE_METERS
	local fallbackPoint = nil
	for i = 1, 50 do
		local headingRad = math.random() * 2 * math.pi
		local candidate = {
			x = startPoint.x + math.cos(headingRad) * distanceMeters,
			y = startPoint.y,
			z = startPoint.z + math.sin(headingRad) * distanceMeters
		}
		if fallbackPoint == nil then
			fallbackPoint = candidate
		end
		if self:isDeployScatterPointOnLand(candidate) then
			return candidate, distanceMeters, startPoint
		end
	end
	return fallbackPoint, distanceMeters, startPoint
end

function SkynetIADSMobilePatrol:issueDeployScatterRoute(entry, destination, speedKmph)
	if entry == nil or entry.group == nil or entry.group:isExist() == false or destination == nil then
		return false
	end
	local startPoint = self:getPatrolReferencePoint(entry)
	if startPoint == nil then
		return false
	end
	local speedMps = mist.utils.kmphToMps(speedKmph)
	local path = {
		mist.ground.buildWP(startPoint, SkynetIADSMobilePatrol.DEFAULT_DEPLOY_SCATTER_FORM, speedMps),
		mist.ground.buildWP({
			x = startPoint.x + 25,
			z = startPoint.z + 25
		}, SkynetIADSMobilePatrol.DEFAULT_DEPLOY_SCATTER_FORM, speedMps),
		mist.ground.buildWP(destination, SkynetIADSMobilePatrol.DEFAULT_DEPLOY_SCATTER_FORM, speedMps),
	}
	local ok = pcall(function()
		mist.goRoute(entry.group, path)
	end)
	return ok == true
end

function SkynetIADSMobilePatrol:calculateDeployScatterTravelTimeSeconds(distanceMeters, speedKmph)
	local speedMps = mist.utils.kmphToMps(speedKmph or self.defaultPatrolSpeedKmph)
	if speedMps <= 0 then
		speedMps = 1
	end
	return math.max(8, math.ceil(distanceMeters / speedMps) + 4)
end

function SkynetIADSMobilePatrol:getDeployScatterDistanceMovedMeters(entry)
	if entry == nil or entry.deployScatterStartPoint == nil then
		return 0
	end
	local currentPoint = self:getPatrolReferencePoint(entry)
	if currentPoint == nil then
		return 0
	end
	return mist.utils.get2DDist(currentPoint, entry.deployScatterStartPoint)
end

function SkynetIADSMobilePatrol:hasReachedDeployScatterDestination(entry)
	if entry == nil or entry.deployScatterDestination == nil then
		return true
	end
	local currentPoint = self:getPatrolReferencePoint(entry)
	if currentPoint == nil then
		return false
	end
	return mist.utils.get2DDist(currentPoint, entry.deployScatterDestination) <= entry.arrivalToleranceMeters
end

function SkynetIADSMobilePatrol:getDeployScatterSpeedKmph(entry)
	local speed = entry.patrolSpeedKmph or self.defaultPatrolSpeedKmph
	if entry.element and entry.element.getHARMRelocationSpeedKmph then
		local okSpeed, relocationSpeed = pcall(function()
			return entry.element:getHARMRelocationSpeedKmph()
		end)
		if okSpeed and relocationSpeed and relocationSpeed > speed then
			speed = relocationSpeed
		end
	end
	return speed
end

function SkynetIADSMobilePatrol:issueDeployScatter(entry)
	if entry.group == nil or entry.group:isExist() == false then
		return false
	end
	local destination, distanceMeters, startPoint = self:calculateDeployScatterPoint(entry)
	if destination == nil then
		return false
	end
	local speedKmph = self:getDeployScatterSpeedKmph(entry)
	local ok = self:issueDeployScatterRoute(entry, destination, speedKmph)
	if ok then
		entry.currentDestination = destination
		entry.lastRouteIssueTime = timer.getTime()
		entry.lastRouteIssueReferencePoint = self:getPatrolReferencePoint(entry)
		entry.deployScatterStartPoint = startPoint
		entry.deployScatterDestination = destination
		entry.deployScatterDeadline = timer.getTime() + self:calculateDeployScatterTravelTimeSeconds(distanceMeters, speedKmph)
		entry.deployScatterMinimumCompletionMeters = math.max(
			SkynetIADSMobilePatrol.DEFAULT_DEPLOY_SCATTER_MIN_COMPLETION_METERS,
			math.floor(distanceMeters * 0.6)
		)
		self:log("Deploy scatter issued for "..entry.groupName.." | speed="..speedKmph.."km/h | distance="..distanceMeters.."m")
	end
	return ok
end

function SkynetIADSMobilePatrol:getThreatRangeMeters(entry)
	local element = entry.element
	local maxRange = 0
	if entry.kind == "MSAM" then
		local launchers = element:getLaunchers()
		for i = 1, #launchers do
			local launcher = launchers[i]
			if launcher:isExist() and launcher.getRange then
				maxRange = math.max(maxRange, launcher:getRange())
			end
		end
		if maxRange > 0 then
			return maxRange * (element:getGoLiveRangeInPercent() / 100)
		end
	end
	local searchRadars = element.getSearchRadars and element:getSearchRadars() or {}
	for i = 1, #searchRadars do
		local radar = searchRadars[i]
		if radar:isExist() and radar.getMaxRangeFindingTarget then
			maxRange = math.max(maxRange, radar:getMaxRangeFindingTarget())
		end
	end
	return maxRange
end

function SkynetIADSMobilePatrol:getMSAMCombatProfile(entry)
	if entry == nil or entry.kind ~= "MSAM" then
		return nil
	end
	local natoName = entry.element.getNatoName and entry.element:getNatoName() or nil
	if natoName ~= "SA-11" then
		return nil
	end
	return {
		alertRangeMeters = mist.utils.NMToMeters(self.sa11MSAMAlertDistanceNm),
		engageRangeMeters = mist.utils.NMToMeters(self.sa11MSAMEngageDistanceNm),
	}
end

function SkynetIADSMobilePatrol:isMoveFireCapable(entry)
	if entry == nil or entry.kind ~= "MSAM" then
		return false
	end
	local natoName = entry.element.getNatoName and entry.element:getNatoName() or nil
	if natoName ~= nil and self.moveFireNatoNames[natoName] == true then
		return true
	end

	local launchers = entry.element.getLaunchers and entry.element:getLaunchers() or {}
	if #launchers == 0 then
		return false
	end

	for i = 1, #launchers do
		local launcher = launchers[i]
		local typeName = launcher and launcher.getTypeName and launcher:getTypeName() or nil
		if typeName == nil then
			local representation = launcher and launcher.getDCSRepresentation and launcher:getDCSRepresentation() or nil
			if representation and representation.getTypeName then
				typeName = representation:getTypeName()
			end
		end
		if typeName == nil or self.moveFireLauncherTypeNames[typeName] ~= true then
			return false
		end
	end

	return true
end

function SkynetIADSMobilePatrol:getDeployTriggerRangeMeters(entry)
	local profile = self:getMSAMCombatProfile(entry)
	if profile then
		return profile.alertRangeMeters
	end
	return self:getThreatRangeMeters(entry)
end

function SkynetIADSMobilePatrol:getCombatRangeMeters(entry)
	local profile = self:getMSAMCombatProfile(entry)
	if profile then
		return profile.engageRangeMeters
	end
	return self:getThreatRangeMeters(entry)
end

function SkynetIADSMobilePatrol:getContactName(contact)
	local targetName = "unknown"
	local okName, name = pcall(function()
		return contact:getName()
	end)
	if okName and name then
		targetName = name
	end
	return targetName
end

function SkynetIADSMobilePatrol:getContactDistanceMeters(entry, contact)
	local radarPoint = self:getPatrolReferencePoint(entry)
	local targetPoint = nil
	if contact and contact.getPosition then
		pcall(function()
			local position = contact:getPosition()
			targetPoint = position and position.p or nil
		end)
	end
	if radarPoint and targetPoint then
		return mist.utils.get2DDist(radarPoint, targetPoint)
	end
	return math.huge
end

function SkynetIADSMobilePatrol:findNearestEligibleContact(entry, maxDistanceMeters)
	local contacts = self.iads:getContacts()
	local nearestContact = nil
	local nearestDistanceMeters = math.huge
	for i = 1, #contacts do
		local contact = contacts[i]
		if contact
			and isAirContact(contact)
			and contact:isIdentifiedAsHARM() == false
			and entry.element:areGoLiveConstraintsSatisfied(contact) then
			local distanceMeters = self:getContactDistanceMeters(entry, contact)
			if distanceMeters <= maxDistanceMeters and distanceMeters < nearestDistanceMeters then
				nearestContact = contact
				nearestDistanceMeters = distanceMeters
			end
		end
	end
	return nearestContact, nearestDistanceMeters
end

function SkynetIADSMobilePatrol:hasAircraftWithinRange(entry, distanceMeters)
	local center = self:getPatrolReferencePoint(entry)
	if center == nil or distanceMeters <= 0 then
		return false
	end
	local enemyAircraft = collectEnemyAirUnits(self.enemyCoalitionId)
	for i = 1, #enemyAircraft do
		local unit = enemyAircraft[i]
		local unitPoint = unit:getPoint()
		if unitPoint and mist.utils.get2DDist(center, unitPoint) <= distanceMeters then
			return true
		end
	end
	return false
end

function SkynetIADSMobilePatrol:buildDeployTriggerInfo(entry, contact, source)
	local radarPoint = self:getPatrolReferencePoint(entry)
	local targetPoint = nil
	if contact and contact.getPosition then
		pcall(function()
			local position = contact:getPosition()
			targetPoint = position and position.p or nil
		end)
	end
	local distanceNm = 0
	local threatRangeNm = 0
	if radarPoint and targetPoint then
		distanceNm = mist.utils.metersToNM(mist.utils.get2DDist(radarPoint, targetPoint))
	end
	local threatRangeMeters = self:getDeployTriggerRangeMeters(entry)
	if threatRangeMeters and threatRangeMeters > 0 then
		threatRangeNm = mist.utils.metersToNM(threatRangeMeters)
	end
	local targetName = self:getContactName(contact)
	local targetType = "unknown"
	local okType, typeName = pcall(function()
		return contact:getTypeName()
	end)
	if okType and typeName then
		targetType = typeName
	end
	return {
		source = source or "unknown",
		time = timer.getTime(),
		contactName = targetName,
		contactType = targetType,
		distanceNm = mist.utils.round(distanceNm, 1),
		threatRangeNm = mist.utils.round(threatRangeNm, 1),
	}
end

function SkynetIADSMobilePatrol:buildAircraftUnitTriggerInfo(entry, unit, source, threatRangeMeters)
	local radarPoint = self:getPatrolReferencePoint(entry)
	local targetPoint = unit and unit.getPoint and unit:getPoint() or nil
	local distanceNm = 0
	local threatRangeNm = 0
	if radarPoint and targetPoint then
		distanceNm = mist.utils.metersToNM(mist.utils.get2DDist(radarPoint, targetPoint))
	end
	if threatRangeMeters and threatRangeMeters > 0 then
		threatRangeNm = mist.utils.metersToNM(threatRangeMeters)
	end
	local targetName = "unknown"
	local okName, unitName = pcall(function()
		return unit:getName()
	end)
	if okName and unitName then
		targetName = unitName
	end
	local targetType = "unknown"
	local okType, typeName = pcall(function()
		return unit:getTypeName()
	end)
	if okType and typeName then
		targetType = typeName
	end
	return {
		source = source or "direct_unit_scan",
		time = timer.getTime(),
		contactName = targetName,
		contactType = targetType,
		distanceNm = mist.utils.round(distanceNm, 1),
		directDistanceNm = mist.utils.round(distanceNm, 1),
		effectiveDistanceNm = mist.utils.round(distanceNm, 1),
		threatRangeNm = mist.utils.round(threatRangeNm, 1),
	}
end

function SkynetIADSMobilePatrol:findSAMThreatContact(entry)
	local moveFireCapable = self:isMoveFireCapable(entry)
	local profile = self:getMSAMCombatProfile(entry)
	if profile then
		local contact, contactDistanceMeters = self:findNearestEligibleContact(entry, profile.alertRangeMeters)
		local directUnit, directUnitDistanceMeters = self:findNearestEnemyAircraftUnit(entry, profile.alertRangeMeters)
		if contact == nil and directUnit == nil then
			return nil
		end
		local effectiveDistanceMeters = math.huge
		if contact ~= nil and contactDistanceMeters < effectiveDistanceMeters then
			effectiveDistanceMeters = contactDistanceMeters
		end
		if directUnit ~= nil and directUnitDistanceMeters < effectiveDistanceMeters then
			effectiveDistanceMeters = directUnitDistanceMeters
		end
		if effectiveDistanceMeters == math.huge then
			return nil
		end

		local shouldGoLive = contact ~= nil and effectiveDistanceMeters <= profile.engageRangeMeters
		local triggerInfo = nil
		if contact ~= nil then
			triggerInfo = self:buildDeployTriggerInfo(
				entry,
				contact,
				shouldGoLive and "contact_scan_engage" or "contact_scan_alert"
			)
			triggerInfo.contactDistanceNm = triggerInfo.distanceNm
		else
			triggerInfo = self:buildAircraftUnitTriggerInfo(
				entry,
				directUnit,
				shouldGoLive and "direct_unit_engage" or "direct_unit_alert",
				profile.alertRangeMeters
			)
			triggerInfo.contactDistanceNm = nil
		end

		triggerInfo.directDistanceNm = nil
		if directUnit ~= nil and directUnitDistanceMeters < math.huge then
			triggerInfo.directDistanceNm = mist.utils.round(mist.utils.metersToNM(directUnitDistanceMeters), 1)
			local okDirectName, directName = pcall(function()
				return directUnit:getName()
			end)
			if okDirectName and directName then
				triggerInfo.directUnitName = directName
			end
		end
		triggerInfo.effectiveDistanceNm = mist.utils.round(mist.utils.metersToNM(effectiveDistanceMeters), 1)
		triggerInfo.engageRangeNm = mist.utils.round(mist.utils.metersToNM(profile.engageRangeMeters), 1)
		triggerInfo.combatMode = shouldGoLive and "engage_fire" or "alert_hold"
		return {
			contact = contact,
			triggerInfo = triggerInfo,
			shouldDeploy = moveFireCapable ~= true,
			shouldGoLive = shouldGoLive,
			shouldWeaponHold = false,
			combatMode = triggerInfo.combatMode,
		}
	end

	if moveFireCapable then
		local threatRangeMeters = self:getThreatRangeMeters(entry)
		if threatRangeMeters <= 0 then
			return nil
		end
		local directUnit, directUnitDistanceMeters = self:findNearestEnemyAircraftUnit(entry, threatRangeMeters)
		if directUnit == nil then
			return nil
		end
		local triggerInfo = self:buildAircraftUnitTriggerInfo(entry, directUnit, "direct_unit_scan", threatRangeMeters)
		triggerInfo.engageRangeNm = mist.utils.round(mist.utils.metersToNM(threatRangeMeters), 1)
		return {
			contact = nil,
			triggerInfo = triggerInfo,
			shouldDeploy = false,
			shouldGoLive = true,
			shouldWeaponHold = false,
			combatMode = "direct_unit_fire",
		}
	end

	local contacts = self.iads:getContacts()
	for i = 1, #contacts do
		local contact = contacts[i]
		if contact
			and isAirContact(contact)
			and contact:isIdentifiedAsHARM() == false
			and entry.element:areGoLiveConstraintsSatisfied(contact)
			and entry.element:isTargetInRange(contact) then
			return {
				contact = contact,
				triggerInfo = self:buildDeployTriggerInfo(entry, contact, "contact_scan"),
				shouldDeploy = moveFireCapable ~= true,
				shouldGoLive = true,
				shouldWeaponHold = false,
				combatMode = "default_fire",
			}
		end
	end
	return nil
end

function SkynetIADSMobilePatrol:applyMSAMThreatDecision(entry, threatDecision, skipPause)
	if entry == nil then
		return false
	end

	if threatDecision == nil then
		entry.combatMode = "searching"
		entry.debugLastCombatAnnouncementKey = nil
		return false
	end

	local now = timer.getTime()
	local wasCombatCommitted = entry.combatCommitted == true
	local triggerInfo = threatDecision.triggerInfo
	if triggerInfo then
		entry.lastDeployTrigger = triggerInfo
	end
	entry.combatMode = threatDecision.combatMode or "default_fire"
	local moveFireCapable = self:isMoveFireCapable(entry)

	if moveFireCapable ~= true and threatDecision.shouldDeploy and entry.state ~= "deployed" and entry.state ~= "deploy_scattering" and skipPause ~= true then
		self:pausePatrolForDeployment(entry, triggerInfo)
	end

	if entry.state == "deploy_scattering" then
		entry.lastThreatTime = timer.getTime()
		entry.noThreatSince = nil
		if threatDecision.shouldGoLive == true then
			if entry.element.targetsInRange ~= nil then
				entry.element.targetsInRange = true
			end
			entry.element:goLive()
			setElementCombatROE(entry.element, threatDecision.shouldWeaponHold == true)
			if threatDecision.contact and threatDecision.contact:isIdentifiedAsHARM() == false and entry.element.informOfContact then
				pcall(function()
					entry.element:informOfContact(threatDecision.contact)
				end)
			end
			if threatDecision.shouldGoLive == true then
				entry.combatCommitted = true
				entry.combatNoTargetSince = nil
				entry.mobileLockUntil = 0
			end
			self:announceCombatState(entry, threatDecision)
		end
		return true
	end

	if threatDecision.shouldGoLive then
		if entry.element.targetsInRange ~= nil then
			entry.element.targetsInRange = true
		end
		if moveFireCapable then
			setElementMovingCombatState(entry.element, threatDecision.shouldWeaponHold == true)
		else
			entry.element:goLive()
			setElementCombatROE(entry.element, threatDecision.shouldWeaponHold == true)
			if threatDecision.contact and threatDecision.contact:isIdentifiedAsHARM() == false and entry.element.informOfContact then
				pcall(function()
					entry.element:informOfContact(threatDecision.contact)
				end)
			end
		end
	else
		forceElementIntoPatrolDarkState(entry.element)
	end

	if moveFireCapable then
		entry.state = "patrolling"
	else
		entry.state = "deployed"
	end
	if threatDecision.shouldGoLive == true then
		entry.combatCommitted = true
		entry.combatNoTargetSince = nil
		entry.mobileLockUntil = 0
	end
	entry.lastThreatTime = now
	entry.noThreatSince = nil
	self:announceCombatState(entry, threatDecision)
	if wasCombatCommitted ~= true and entry.combatCommitted == true and _G.redIADSSiblingCoordination and _G.redIADSSiblingCoordination.requestImmediateEvaluation then
		pcall(function()
			_G.redIADSSiblingCoordination:requestImmediateEvaluation("msam_threat:" .. tostring(entry.groupName))
		end)
	end
	return true
end

function SkynetIADSMobilePatrol:hasSAMCombatThreat(entry)
	if entry == nil or entry.kind ~= "MSAM" then
		return false
	end

	local combatRangeMeters = self:getCombatRangeMeters(entry)
	if combatRangeMeters <= 0 then
		return false
	end

	local siblingInfo = self:getSiblingInfo(entry)
	if siblingInfo ~= nil and siblingInfo.mode == "denial" and siblingInfo.role == "primary" then
		local denialRangeMeters = mist.utils.NMToMeters(
			siblingInfo.denialAlertDistanceNm
			or self.sa11MSAMAlertDistanceNm
			or SkynetIADSMobilePatrol.DEFAULT_SA11_MSAM_ALERT_DISTANCE_NM
		)
		local directUnit = self:findNearestEnemyAircraftUnit(entry, denialRangeMeters)
		if directUnit ~= nil then
			return true
		end
		local contacts = self.iads:getContacts()
		for i = 1, #contacts do
			local contact = contacts[i]
			if contact
				and isAirContact(contact)
				and contact:isIdentifiedAsHARM() == false
				and entry.element:areGoLiveConstraintsSatisfied(contact)
				and self:getContactDistanceMeters(entry, contact) <= denialRangeMeters then
				return true
			end
		end
	end

	if self:isMoveFireCapable(entry) then
		local directUnit = self:findNearestEnemyAircraftUnit(entry, combatRangeMeters)
		return directUnit ~= nil
	end

	local profile = self:getMSAMCombatProfile(entry)
	if profile then
		local directUnit = self:findNearestEnemyAircraftUnit(entry, combatRangeMeters)
		if directUnit ~= nil then
			return true
		end
	end
	local contacts = self.iads:getContacts()
	for i = 1, #contacts do
		local contact = contacts[i]
		if contact
			and isAirContact(contact)
			and contact:isIdentifiedAsHARM() == false
			and entry.element:areGoLiveConstraintsSatisfied(contact) then
			if profile then
				if self:getContactDistanceMeters(entry, contact) <= combatRangeMeters then
					return true
				end
			elseif entry.element:isTargetInRange(contact) then
				return true
			end
		end
	end
	return false
end

function SkynetIADSMobilePatrol:findNearestEnemyAircraftUnit(entry, maxDistanceMeters)
	local center = self:getPatrolReferencePoint(entry)
	if center == nil or maxDistanceMeters <= 0 then
		return nil, math.huge
	end
	local enemyAircraft = collectEnemyAirUnits(self.enemyCoalitionId)
	local nearestUnit = nil
	local nearestDistanceMeters = math.huge
	for i = 1, #enemyAircraft do
		local unit = enemyAircraft[i]
		local unitPoint = unit:getPoint()
		if unitPoint then
			local distanceMeters = mist.utils.get2DDist(center, unitPoint)
			if distanceMeters <= maxDistanceMeters and distanceMeters < nearestDistanceMeters then
				nearestUnit = unit
				nearestDistanceMeters = distanceMeters
			end
		end
	end
	return nearestUnit, nearestDistanceMeters
end

function SkynetIADSMobilePatrol:findMEWThreat(entry)
	local searchRange = self:getThreatRangeMeters(entry)
	if searchRange <= 0 then
		return false
	end
	return self:hasAircraftWithinRange(entry, searchRange)
end

function SkynetIADSMobilePatrol:isHarmEvading(entry)
	return entry.element.harmSilenceID ~= nil or entry.element.harmRelocationInProgress == true
end

function SkynetIADSMobilePatrol:pausePatrolForDeployment(entry, triggerInfo)
	local wasDeployed = entry.state == "deployed"
	applyFormationIntervalToEntry(entry, SkynetIADSMobilePatrol.DEFAULT_DEPLOY_FORMATION_INTERVAL_METERS)
	local scatterIssued = self:issueDeployScatter(entry) == true
	if scatterIssued ~= true then
		self:issueHold(entry)
		entry.deployScatterStartPoint = nil
		entry.deployScatterDestination = nil
		entry.deployScatterDeadline = 0
		entry.deployScatterMinimumCompletionMeters = 0
		entry.state = "deployed"
	else
		entry.state = "deploy_scattering"
	end
	entry.noThreatSince = nil
	entry.lastThreatTime = timer.getTime()
	entry.debugLastCombatAnnouncementKey = nil
	if triggerInfo then
		entry.lastDeployTrigger = triggerInfo
		self:log(
			"MSAM deploy | "..entry.groupName
			.." | source="..tostring(triggerInfo.source)
			.." | contact="..tostring(triggerInfo.contactName)
			.." | type="..tostring(triggerInfo.contactType)
			.." | distance="..tostring(triggerInfo.distanceNm).."nm"
			.." | threatRange="..tostring(triggerInfo.threatRangeNm).."nm"
			.." | mode="..tostring(triggerInfo.combatMode or "default")
			.." | closure="..tostring(triggerInfo.closingRateNmps or "n/a")
		)
	end
	if wasDeployed ~= true then
		local deployMode = triggerInfo and (triggerInfo.combatMode or triggerInfo.source) or "default"
		local targetName = triggerInfo and triggerInfo.contactName or "unknown"
		self:notifyDebug(
			entry.groupName
			.. " 停车展开 | mode="
			.. tostring(deployMode)
			.. " | target="
			.. tostring(targetName)
		)
	end
end

function SkynetIADSMobilePatrol:beginPatrol(entry)
	local previousState = entry.state
	entry.state = "patrolling"
	entry.combatMode = "patrolling"
	entry.combatCommitted = false
	entry.combatNoTargetSince = nil
	entry.noThreatSince = nil
	entry.lastThreatTime = 0
	entry.contactKinematics = {}
	entry.debugLastCombatAnnouncementKey = nil
	forceElementIntoPatrolDarkState(entry.element)
	applyFormationIntervalToEntry(entry, SkynetIADSMobilePatrol.DEFAULT_PATROL_FORMATION_INTERVAL_METERS)
	entry.currentDestination = nil
	entry.patrolRefreshDelays = mist.utils.deepCopy(self.defaultPatrolRefreshDelays)
	entry.nextPatrolRefreshTime = timer.getTime() + entry.patrolRefreshDelays[1]
	self:issuePatrolRoute(entry)
	if previousState ~= "patrolling" then
		self:notifyDebug(entry.groupName .. " 恢复巡逻")
	end
end

function SkynetIADSMobilePatrol:advancePatrol(entry, force)
	if entry.state ~= "patrolling" then
		return false
	end
	if entry.group == nil or entry.group:isExist() == false or #entry.routePoints == 0 then
		return false
	end
	local nextPoint = entry.routePoints[entry.currentWaypointIndex]
	if nextPoint == nil then
		entry.currentWaypointIndex = 1
		nextPoint = entry.routePoints[1]
	end
	if force ~= true and entry.currentDestination and self:getWaypointDistance(entry, entry.currentDestination) > entry.arrivalToleranceMeters then
		return false
	end
	if self:getWaypointDistance(entry, nextPoint) <= entry.arrivalToleranceMeters then
		entry.currentWaypointIndex = (entry.currentWaypointIndex % #entry.routePoints) + 1
		nextPoint = entry.routePoints[entry.currentWaypointIndex]
	end
	if nextPoint then
		local startIndex = entry.currentWaypointIndex
		local route = self:buildRoadPatrolRoute(entry, startIndex)
		if route and pcall(function()
			mist.goRoute(entry.group, route)
		end) then
			entry.currentDestination = nextPoint
			entry.lastRouteIssueTime = timer.getTime()
			entry.lastRouteIssueReferencePoint = self:getPatrolReferencePoint(entry)
			self:log("Road patrol issued for "..entry.groupName.." | wp="..tostring(startIndex).." | speed="..entry.patrolSpeedKmph.."km/h")
			entry.currentWaypointIndex = (entry.currentWaypointIndex % #entry.routePoints) + 1
			return true
		end
	end
	return false
end

function SkynetIADSMobilePatrol:handleDeployedState(entry)
	local resumeRange = self:getDeployTriggerRangeMeters(entry) * entry.resumeMultiplier
	if self:hasAircraftWithinRange(entry, resumeRange) then
		entry.noThreatSince = nil
		entry.lastThreatTime = timer.getTime()
		return
	end
	if entry.noThreatSince == nil then
		entry.noThreatSince = timer.getTime()
		return
	end
	if (timer.getTime() - entry.noThreatSince) >= entry.resumeDelaySeconds then
		self:beginPatrol(entry)
	end
end

function SkynetIADSMobilePatrol:handleDeployScatterState(entry)
	local timedOut = timer.getTime() >= (entry.deployScatterDeadline or 0)
	local movedDistance = self:getDeployScatterDistanceMovedMeters(entry)
	local movedEnough = movedDistance >= (entry.deployScatterMinimumCompletionMeters or 0)
	if self:hasReachedDeployScatterDestination(entry) or (timedOut and movedEnough) then
		entry.state = "deployed"
		entry.currentDestination = nil
		entry.deployScatterStartPoint = nil
		entry.deployScatterDestination = nil
		entry.deployScatterDeadline = 0
		entry.deployScatterMinimumCompletionMeters = 0
		self:log("Deploy scatter complete for "..entry.groupName.." | moved="..mist.utils.round(movedDistance, 0).."m")
		self:notifyDebug(entry.groupName .. " 散开完成，进入战斗展开")
		return true
	end
	if timedOut then
		entry.deployScatterDeadline = timer.getTime() + SkynetIADSMobilePatrol.DEFAULT_DEPLOY_SCATTER_CHECK_INTERVAL_SECONDS
	end
	return false
end

function SkynetIADSMobilePatrol:getSiblingInfo(entry)
	if SkynetIADSSiblingCoordination and SkynetIADSSiblingCoordination.getFamilyForElement then
		return SkynetIADSSiblingCoordination.getFamilyForElement(entry.element)
	end
	return nil
end

function SkynetIADSMobilePatrol:updateEntry(entry)
	if entry.element:isDestroyed() or entry.group == nil or entry.group:isExist() == false then
		return
	end

	local now = timer.getTime()
	local moveFireCapable = self:isMoveFireCapable(entry)

	if moveFireCapable and entry.element.harmSilenceID ~= nil and entry.element.harmRelocationInProgress ~= true then
		entry.state = "patrolling"
		entry.combatMode = "harm_silent"
		entry.noThreatSince = nil
		return
	end

	if self:isHarmEvading(entry) then
		entry.state = "harm_evading"
		entry.noThreatSince = nil
		return
	end

	if entry.state == "deploy_scattering" then
		if self:handleDeployScatterState(entry) ~= true then
			if entry.kind == "MSAM" then
				local threatDecision = self:findSAMThreatContact(entry)
				if threatDecision and threatDecision.shouldGoLive == true then
					self:applyMSAMThreatDecision(entry, threatDecision, true)
				end
			end
			entry.noThreatSince = nil
			entry.lastThreatTime = timer.getTime()
			return
		end
	end

	local siblingInfo = self:getSiblingInfo(entry)
	local siblingPassiveRelocate = siblingInfo ~= nil and siblingInfo.role == "passive" and siblingInfo.passiveMode == "relocate"
	local siblingPassiveHold = siblingInfo ~= nil and siblingInfo.role == "passive" and siblingInfo.passiveMode == "hold_dark"
	local siblingPassiveStandby = siblingInfo ~= nil and siblingInfo.role == "passive" and siblingInfo.passiveMode == "standby"

	if siblingPassiveHold then
		entry.combatCommitted = false
		entry.combatNoTargetSince = nil
		entry.noThreatSince = nil
		if entry.state == "deployed" then
			entry.state = "patrolling"
			entry.combatMode = "patrolling"
		end
		return
	end

	if siblingPassiveStandby then
		entry.combatCommitted = false
		entry.combatNoTargetSince = nil
		entry.noThreatSince = nil
		entry.lastThreatTime = now
		if entry.state ~= "deployed" then
			entry.state = "deployed"
			entry.combatMode = "sibling_standby"
		end
		return
	end

	if siblingPassiveRelocate and entry.state ~= "patrolling" then
		self:beginPatrol(entry)
		return
	end

	if entry.mobileLockUntil and entry.mobileLockUntil > now then
		if entry.state ~= "patrolling" then
			self:beginPatrol(entry)
		end
		entry.noThreatSince = nil
		entry.combatNoTargetSince = nil
		return
	end
	entry.mobileLockUntil = 0

	local threatPresent = false
	if entry.kind == "MSAM" and siblingPassiveRelocate ~= true then
		local threatDecision = nil
		local allowThreatScan = true
		if siblingInfo ~= nil and _G.redIADSSiblingCoordination and _G.redIADSSiblingCoordination.arbitrateThreatDecision then
			local okArbitrate, arbitratedDecision, arbitratedAllowed = pcall(function()
				return _G.redIADSSiblingCoordination:arbitrateThreatDecision(entry.element)
			end)
			if okArbitrate then
				threatDecision = arbitratedDecision
				allowThreatScan = arbitratedAllowed ~= false
			end
		end
		if threatDecision == nil and allowThreatScan then
			threatDecision = self:findSAMThreatContact(entry)
		end

		if entry.combatCommitted == true then
			local combatThreatPresent = self:hasSAMCombatThreat(entry)
			if combatThreatPresent == true then
				entry.combatNoTargetSince = nil
			else
				if entry.combatNoTargetSince == nil then
					entry.combatNoTargetSince = now
				elseif (now - entry.combatNoTargetSince) >= entry.combatExitNoTargetSeconds then
					entry.combatCommitted = false
					entry.combatNoTargetSince = nil
					entry.mobileLockUntil = now + entry.postCombatMobileSeconds
					entry.combatMode = "patrolling"
					entry.debugLastCombatAnnouncementKey = nil
					self:notifyDebug(entry.groupName .. " combat exit -> mobile")
					self:beginPatrol(entry)
					if _G.redIADSSiblingCoordination and _G.redIADSSiblingCoordination.requestImmediateEvaluation then
						pcall(function()
							_G.redIADSSiblingCoordination:requestImmediateEvaluation("combat_exit:" .. tostring(entry.groupName))
						end)
					end
					return
				end
			end

			if threatDecision == nil or threatDecision.shouldGoLive ~= true then
				local triggerInfo = threatDecision and threatDecision.triggerInfo or entry.lastDeployTrigger or nil
				if triggerInfo then
					triggerInfo.combatMode = "combat_latched"
				end
				threatDecision = {
					contact = threatDecision and threatDecision.contact or nil,
					triggerInfo = triggerInfo,
					shouldDeploy = true,
					shouldGoLive = true,
					shouldWeaponHold = false,
					combatMode = "combat_latched",
				}
			end
		else
			entry.combatNoTargetSince = nil
		end

		threatPresent = threatDecision ~= nil
		if threatDecision then
			self:applyMSAMThreatDecision(entry, threatDecision)
			return
		elseif self:isMoveFireCapable(entry) and entry.combatMode ~= "patrolling" then
			forceElementIntoPatrolDarkState(entry.element)
			entry.combatMode = "patrolling"
			entry.debugLastCombatAnnouncementKey = nil
		end
	elseif entry.kind ~= "MSAM" then
		threatPresent = self:findMEWThreat(entry)
		if threatPresent and entry.state ~= "deployed" then
			self:pausePatrolForDeployment(entry)
			entry.element:goLive()
			entry.combatMode = "default_fire"
		end
	end

	if threatPresent then
		entry.state = "deployed"
		entry.lastThreatTime = timer.getTime()
		entry.noThreatSince = nil
		return
	end

	if entry.state == "harm_evading" then
		if self:isMoveFireCapable(entry) then
			entry.state = "patrolling"
			entry.combatMode = "patrolling"
		else
			entry.state = "deployed"
		end
	end

	if entry.state == "deployed" then
		self:handleDeployedState(entry)
		return
	end

	if entry.state ~= "patrolling" then
		self:beginPatrol(entry)
		return
	end

	if entry.nextPatrolRefreshTime and timer.getTime() >= entry.nextPatrolRefreshTime then
		forceElementIntoPatrolDarkState(entry.element)
		self:log("Patrol refresh reissued for "..entry.groupName.." | delayed startup refresh")
		self:issuePatrolRoute(entry)
		table.remove(entry.patrolRefreshDelays, 1)
		if #entry.patrolRefreshDelays > 0 then
			entry.nextPatrolRefreshTime = timer.getTime() + entry.patrolRefreshDelays[1]
		else
			entry.nextPatrolRefreshTime = nil
		end
	end

	if self:shouldReissuePatrolRoute(entry) then
		self:log("Patrol route reissued for "..entry.groupName.." | group appears stationary")
		self:issuePatrolRoute(entry)
	end
end

function SkynetIADSMobilePatrol:tick(_, time)
	for i = 1, #self.entries do
		self:updateEntry(self.entries[i])
	end
	return time + self.checkInterval
end

function SkynetIADSMobilePatrol:start()
	if self.taskId then
		return self
	end
	self.taskId = timer.scheduleFunction(function(_, time)
		return self:tick(_, time)
	end, {}, timer.getTime() + self.checkInterval)
	return self
end

function SkynetIADSMobilePatrol:registerElement(kind, element, options)
	local groupName = getGroupNameFromElement(element)
	if groupName == nil then
		self:log("Unable to register " .. kind .. " without group: " .. tostring(element:getDCSName()))
		trigger.action.outText("Mobile Patrol: unable to register " .. tostring(element:getDCSName()) .. " | no group", 10)
		return nil
	end

	local routePoints = getRoutePointsFromMissionGroup(groupName)
	if #routePoints == 0 then
		self:log("Skipping " .. element:getDCSName() .. " because no readable mission route points were found")
		trigger.action.outText("Mobile Patrol: skipping " .. element:getDCSName() .. " | no readable mission route points", 10)
		return nil
	end

	local group = Group.getByName(groupName)
	if group == nil or group:isExist() == false then
		self:log("Skipping " .. element:getDCSName() .. " because group does not exist: " .. groupName)
		trigger.action.outText("Mobile Patrol: skipping " .. element:getDCSName() .. " | group missing", 10)
		return nil
	end

	local resumeMultiplier = (options and options.resumeMultiplier)
	if resumeMultiplier == nil then
		if kind == "MSAM" then
			resumeMultiplier = self.defaultMSAMResumeMultiplier
		else
			resumeMultiplier = self.defaultResumeMultiplier
		end
	end

	local entry = {
		kind = kind,
		element = element,
		group = group,
		groupName = groupName,
		routePoints = routePoints,
		currentWaypointIndex = 1,
		currentDestination = nil,
		patrolSpeedKmph = (options and options.patrolSpeedKmph) or self.defaultPatrolSpeedKmph,
		resumeDelaySeconds = (options and options.resumeDelaySeconds) or self.defaultResumeDelaySeconds,
		resumeMultiplier = resumeMultiplier,
		arrivalToleranceMeters = (options and options.arrivalToleranceMeters) or self.defaultArrivalToleranceMeters,
		state = "patrolling",
		combatMode = "patrolling",
		combatCommitted = false,
		combatNoTargetSince = nil,
		mobileLockUntil = 0,
		combatExitNoTargetSeconds = (options and options.combatExitNoTargetSeconds) or self.defaultCombatExitNoTargetSeconds,
		postCombatMobileSeconds = (options and options.postCombatMobileSeconds) or self.defaultPostCombatMobileSeconds,
		lastThreatTime = 0,
		noThreatSince = nil,
		lastRouteIssueTime = nil,
		lastRouteIssueReferencePoint = nil,
		deployScatterStartPoint = nil,
		deployScatterDestination = nil,
		deployScatterDeadline = 0,
		deployScatterMinimumCompletionMeters = 0,
		patrolRefreshDelays = {},
		nextPatrolRefreshTime = nil,
		manager = self,
	}
	entry.currentWaypointIndex = self:selectStartingWaypointIndex(entry)
	self:registerEntryForElement(element, entry)
	self:beginPatrol(entry)
	return entry
end

function SkynetIADSMobilePatrol:registerSAMSite(samSite, options)
	return self:registerElement("MSAM", samSite, options)
end

function SkynetIADSMobilePatrol:registerEWRadar(ewRadar, options)
	return self:registerElement("MEW", ewRadar, options)
end

function SkynetIADSMobilePatrol:registerByPrefixes(mobileSAMPrefix, mobileEWPrefix, options)
	local registeredSAM = 0
	local registeredEW = 0
	local samSites = self.iads:getSAMSites()
	for i = 1, #samSites do
		local samSite = samSites[i]
		if samSiteMatchesPrefix(samSite, mobileSAMPrefix) then
			if self:registerSAMSite(samSite, options) then
				registeredSAM = registeredSAM + 1
			end
		end
	end

	local ewRadars = self.iads:getEarlyWarningRadars()
	for i = 1, #ewRadars do
		local ewRadar = ewRadars[i]
		if ewRadarMatchesPrefix(ewRadar, mobileEWPrefix) then
			if self:registerEWRadar(ewRadar, options) then
				registeredEW = registeredEW + 1
			end
		end
	end

	self:log("Registered mobile patrol assets | MSAM=" .. registeredSAM .. " | MEW=" .. registeredEW)
	return registeredSAM, registeredEW
end

function SkynetIADSMobilePatrol.create(iads, config)
	local patrol = {
		iads = iads,
		entries = {},
		enemyCoalitionId = getEnemyCoalition(iads.coalitionID),
		checkInterval = (config and config.checkInterval) or SkynetIADSMobilePatrol.DEFAULT_CHECK_INTERVAL,
		defaultPatrolSpeedKmph = (config and config.defaultPatrolSpeedKmph) or SkynetIADSMobilePatrol.DEFAULT_PATROL_SPEED_KMPH,
		defaultResumeDelaySeconds = (config and config.defaultResumeDelaySeconds) or SkynetIADSMobilePatrol.DEFAULT_RESUME_DELAY_SECONDS,
		defaultResumeMultiplier = (config and config.defaultResumeMultiplier) or SkynetIADSMobilePatrol.DEFAULT_RESUME_MULTIPLIER,
		defaultMSAMResumeMultiplier = (config and config.defaultMSAMResumeMultiplier) or SkynetIADSMobilePatrol.DEFAULT_MSAM_RESUME_MULTIPLIER,
		sa11MSAMAlertDistanceNm = (config and config.sa11MSAMAlertDistanceNm) or SkynetIADSMobilePatrol.DEFAULT_SA11_MSAM_ALERT_DISTANCE_NM,
		sa11MSAMEngageDistanceNm = (config and config.sa11MSAMEngageDistanceNm) or SkynetIADSMobilePatrol.DEFAULT_SA11_MSAM_ENGAGE_DISTANCE_NM,
		defaultCombatExitNoTargetSeconds = (config and config.defaultCombatExitNoTargetSeconds) or SkynetIADSMobilePatrol.DEFAULT_COMBAT_EXIT_NO_TARGET_SECONDS,
		defaultPostCombatMobileSeconds = (config and config.defaultPostCombatMobileSeconds) or SkynetIADSMobilePatrol.DEFAULT_POST_COMBAT_MOBILE_SECONDS,
		defaultArrivalToleranceMeters = (config and config.defaultArrivalToleranceMeters) or SkynetIADSMobilePatrol.DEFAULT_ARRIVAL_TOLERANCE_METERS,
		defaultRouteReissueSeconds = (config and config.defaultRouteReissueSeconds) or SkynetIADSMobilePatrol.DEFAULT_ROUTE_REISSUE_SECONDS,
		defaultMinMovementMeters = (config and config.defaultMinMovementMeters) or SkynetIADSMobilePatrol.DEFAULT_MIN_MOVEMENT_METERS,
		defaultPatrolRefreshDelays = (config and config.defaultPatrolRefreshDelays) or SkynetIADSMobilePatrol.DEFAULT_PATROL_REFRESH_DELAYS,
		moveFireNatoNames = mist.utils.deepCopy((config and config.moveFireNatoNames) or SkynetIADSMobilePatrol.DEFAULT_MOVE_FIRE_NATO_NAMES),
		moveFireLauncherTypeNames = mist.utils.deepCopy((config and config.moveFireLauncherTypeNames) or SkynetIADSMobilePatrol.DEFAULT_MOVE_FIRE_LAUNCHER_TYPE_NAMES),
	}
	setmetatable(patrol, SkynetIADSMobilePatrol)
	return patrol
end

function SkynetIADSMobilePatrol.installHooks()
	if SkynetIADSMobilePatrol._hooksInstalled then
		return
	end
	SkynetIADSMobilePatrol._hooksInstalled = true

	local originalSAMInformOfContact = SkynetIADSSamSite.informOfContact
	function SkynetIADSSamSite:informOfContact(contact)
		local hadTargetInRange = self.targetsInRange == true
		local entry = SkynetIADSMobilePatrol.getEntryForElement(self)
		local moveFireCapable = entry and entry.manager and entry.manager.isMoveFireCapable and entry.manager:isMoveFireCapable(entry) == true
		if entry and entry.kind == "MSAM" and isAirContact(contact) == false then
			return nil
		end
		if entry and entry.kind == "MSAM" then
			local profile = entry.manager:getMSAMCombatProfile(entry)
			if profile and isAirContact(contact) and contact:isIdentifiedAsHARM() == false and self:areGoLiveConstraintsSatisfied(contact) == true then
				local contactDistanceMeters = entry.manager:getContactDistanceMeters(entry, contact)
				local directUnit, directUnitDistanceMeters = entry.manager:findNearestEnemyAircraftUnit(entry, profile.alertRangeMeters)
				local effectiveDistanceMeters = contactDistanceMeters
				if directUnit ~= nil and directUnitDistanceMeters < effectiveDistanceMeters then
					effectiveDistanceMeters = directUnitDistanceMeters
				end
				if effectiveDistanceMeters <= profile.alertRangeMeters then
					if entry.state == "patrolling" and moveFireCapable ~= true then
						entry.manager:pausePatrolForDeployment(
							entry,
							entry.manager:buildDeployTriggerInfo(entry, contact, "inform_of_contact_alert")
						)
					end
					if effectiveDistanceMeters <= profile.engageRangeMeters then
						return originalSAMInformOfContact(self, contact)
					end
					return
				end
			end
		end

		local shouldDeployFromThisContact = false
		local deployTriggerInfo = nil
		if entry and hadTargetInRange == false and entry.state == "patrolling" then
			shouldDeployFromThisContact =
				isAirContact(contact)
				and
				self:areGoLiveConstraintsSatisfied(contact) == true
				and self:isTargetInRange(contact)
				and (
					contact:isIdentifiedAsHARM() == false
					or (contact:isIdentifiedAsHARM() == true and self:getCanEngageHARM() == true)
				)
			if shouldDeployFromThisContact then
				deployTriggerInfo = entry.manager:buildDeployTriggerInfo(entry, contact, "inform_of_contact")
			end
		end
		if shouldDeployFromThisContact and moveFireCapable ~= true then
			entry.manager:pausePatrolForDeployment(entry, deployTriggerInfo)
		end
		local result = originalSAMInformOfContact(self, contact)
		if entry and hadTargetInRange == false and self.targetsInRange == true then
			local radarPoint = entry.manager:getPatrolReferencePoint(entry)
			local targetPoint = contact:getPosition().p
			local distanceNm = 0
			local threatRangeNm = 0
			if radarPoint and targetPoint then
				distanceNm = mist.utils.metersToNM(mist.utils.get2DDist(radarPoint, targetPoint))
			end
			local threatRangeMeters = entry.manager:getThreatRangeMeters(entry)
			if threatRangeMeters and threatRangeMeters > 0 then
				threatRangeNm = mist.utils.metersToNM(threatRangeMeters)
			end
			local targetName = "unknown"
			local okName, name = pcall(function()
				return contact:getName()
			end)
			if okName and name then
				targetName = name
			end
			entry.manager:log("informOfContact deploy | "..entry.groupName.." | contact="..targetName.." | distance="..mist.utils.round(distanceNm, 1).."nm | threatRange="..mist.utils.round(threatRangeNm, 1).."nm")
		end
		return result
	end

	local originalSAMSetToCorrectAutonomousState = SkynetIADSAbstractRadarElement.setToCorrectAutonomousState
	function SkynetIADSSamSite:setToCorrectAutonomousState()
		local entry = SkynetIADSMobilePatrol.getEntryForElement(self)
		if entry and (entry.state == "patrolling" or entry.state == "harm_evading") then
			self.isAutonomous = false
			forceElementIntoPatrolDarkState(self)
			return
		end
		return originalSAMSetToCorrectAutonomousState(self)
	end

	local originalEWSetToCorrectAutonomousState = SkynetIADSEWRadar.setToCorrectAutonomousState
	function SkynetIADSEWRadar:setToCorrectAutonomousState()
		local entry = SkynetIADSMobilePatrol.getEntryForElement(self)
		if entry and (entry.state == "patrolling" or entry.state == "harm_evading") then
			self.isAutonomous = false
			forceElementIntoPatrolDarkState(self)
			return
		end
		return originalEWSetToCorrectAutonomousState(self)
	end

	local originalGoSilentToEvadeHARM = SkynetIADSAbstractRadarElement.goSilentToEvadeHARM
	local function goSilentToEvadeHARMWhileMoving(element, timeToImpact)
		local now = timer.getTime()
		if element.harmSilenceID ~= nil or element.harmRelocationInProgress == true then
			return false
		end
		if element.harmReactionLockUntil ~= nil and now < element.harmReactionLockUntil then
			return false
		end
		element.harmReactionLockUntil = now + element.harmReactionCooldownSeconds
		element.minHarmShutdownTime = element:calculateMinimalShutdownTimeInSeconds(timeToImpact)
		element.maxHarmShutDownTime = element:calculateMaximalShutdownTimeInSeconds(element.minHarmShutdownTime)
		element.harmShutdownTime = element:calculateHARMShutdownTime()
		if element.iads:getDebugSettings().harmDefence then
			element.iads:printOutputToLog("HARM DEFENCE SHUTDOWN + CONTINUE MOVING: "..element:getDCSName().." | FOR: "..element.harmShutdownTime.." seconds | TTI: "..timeToImpact)
		end
		element.harmSilenceID = mist.scheduleFunction(SkynetIADSAbstractRadarElement.finishHarmDefence, {element}, timer.getTime() + element.harmShutdownTime, 1)
		setElementMovingSilenceState(element)
		return true
	end

	function SkynetIADSAbstractRadarElement:goSilentToEvadeHARM(timeToImpact)
		local entry = SkynetIADSMobilePatrol.getEntryForElement(self)
		local shouldAnnounce = false
		local moveFireCapable = false
		if entry then
			shouldAnnounce = entry.debugHarmActive ~= true
			moveFireCapable = entry.manager and entry.manager.isMoveFireCapable and entry.manager:isMoveFireCapable(entry) == true
		end
		local result
		if moveFireCapable then
			result = goSilentToEvadeHARMWhileMoving(self, timeToImpact)
		else
			result = originalGoSilentToEvadeHARM(self, timeToImpact)
		end
		if result ~= false and entry and (self.harmRelocationInProgress == true or moveFireCapable) then
			if moveFireCapable then
				entry.state = "patrolling"
				entry.combatMode = "harm_silent"
			else
				entry.state = "harm_evading"
			end
			entry.noThreatSince = nil
			entry.debugHarmActive = true
			entry.debugLastCombatAnnouncementKey = nil
			if shouldAnnounce and entry.manager and entry.manager.notifyDebug then
				entry.manager:notifyDebug(entry.groupName .. " 进入HARM规避")
			end
		end
		if result ~= false and _G.redIADSSiblingCoordination and _G.redIADSSiblingCoordination.requestImmediateEvaluation then
			pcall(function()
				_G.redIADSSiblingCoordination:requestImmediateEvaluation("harm_evade_start:" .. tostring(self:getDCSName()))
			end)
		end
		return result
	end

	local originalFinishHarmDefence = SkynetIADSAbstractRadarElement.finishHarmDefence
	function SkynetIADSAbstractRadarElement.finishHarmDefence(self)
		local entry = SkynetIADSMobilePatrol.getEntryForElement(self)
		local shouldAnnounce = entry and entry.debugHarmActive == true
		local result = originalFinishHarmDefence(self)
		if entry then
			if entry.manager and entry.manager.isMoveFireCapable and entry.manager:isMoveFireCapable(entry) == true then
				entry.state = "patrolling"
				entry.combatMode = "patrolling"
			end
			entry.debugHarmActive = false
			entry.debugLastCombatAnnouncementKey = nil
			if shouldAnnounce and entry.manager and entry.manager.notifyDebug then
				entry.manager:notifyDebug(entry.groupName .. " HARM规避结束")
			end
		end
		if _G.redIADSSiblingCoordination and _G.redIADSSiblingCoordination.requestImmediateEvaluation then
			pcall(function()
				_G.redIADSSiblingCoordination:requestImmediateEvaluation("harm_evade_end:" .. tostring(self:getDCSName()))
			end)
		end
		return result
	end
end

SkynetIADSMobilePatrol.installHooks()
MobileIADSPatrol = SkynetIADSMobilePatrol
trigger.action.outText("Skynet Mobile Patrol module loaded", 10)

end

do

SkynetIADSSiblingCoordination = {}
SkynetIADSSiblingCoordination.__index = SkynetIADSSiblingCoordination

SkynetIADSSiblingCoordination._familyByElement = setmetatable({}, { __mode = "k" })
SkynetIADSSiblingCoordination._memberByElement = setmetatable({}, { __mode = "k" })

SkynetIADSSiblingCoordination.DEFAULT_CHECK_INTERVAL = 1
SkynetIADSSiblingCoordination.DEFAULT_PASSIVE_ACTION = "hold_dark"
SkynetIADSSiblingCoordination.DEFAULT_MODE = "ambush"
SkynetIADSSiblingCoordination.DEFAULT_DENIAL_ALERT_DISTANCE_NM = 25

local function setGroundROE(controller, weaponHold)
    pcall(function()
        controller:setOption(
            AI.Option.Ground.id.ROE,
            weaponHold and AI.Option.Ground.val.ROE.WEAPON_HOLD or AI.Option.Ground.val.ROE.OPEN_FIRE
        )
    end)
end

local function setPatrolAlarmState(controller)
    pcall(function()
        controller:setOption(AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.GREEN)
    end)
end

local function setCombatAlarmState(controller)
    pcall(function()
        controller:setOption(AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.RED)
    end)
end

local function appendUniqueRepresentation(representations, representation, seenKeys)
    if representation == nil or representation.isExist == nil or representation:isExist() == false then
        return
    end
    local key = nil
    local okName, name = pcall(function()
        return representation:getName()
    end)
    if okName and name then
        key = name
    end
    if key == nil then
        key = tostring(representation)
    end
    if seenKeys[key] then
        return
    end
    seenKeys[key] = true
    representations[#representations + 1] = representation
end

local function collectElementEmitterRepresentations(element)
    local representations = {}
    local seenKeys = {}
    appendUniqueRepresentation(representations, element:getDCSRepresentation(), seenKeys)

    local searchRadars = element.getSearchRadars and element:getSearchRadars() or {}
    for i = 1, #searchRadars do
        appendUniqueRepresentation(representations, searchRadars[i]:getDCSRepresentation(), seenKeys)
    end

    local trackingRadars = element.getTrackingRadars and element:getTrackingRadars() or {}
    for i = 1, #trackingRadars do
        appendUniqueRepresentation(representations, trackingRadars[i]:getDCSRepresentation(), seenKeys)
    end

    local launchers = element.getLaunchers and element:getLaunchers() or {}
    for i = 1, #launchers do
        appendUniqueRepresentation(representations, launchers[i]:getDCSRepresentation(), seenKeys)
    end

    return representations
end

local function applyDarkStandbyToRepresentation(representation)
    if representation == nil or representation.isExist == nil or representation:isExist() == false then
        return
    end
    pcall(function()
        representation:enableEmission(false)
    end)
    local okController, controller = pcall(function()
        return representation:getController()
    end)
    if okController and controller then
        pcall(function()
            controller:setOnOff(true)
        end)
        setPatrolAlarmState(controller)
        setGroundROE(controller, true)
    end
end

local function forceElementIntoDarkStandby(element)
    if element == nil or element.isDestroyed == nil or element:isDestroyed() then
        return
    end
    local representations = collectElementEmitterRepresentations(element)
    for i = 1, #representations do
        applyDarkStandbyToRepresentation(representations[i])
    end
    local controller = element.getController and element:getController() or nil
    if controller then
        pcall(function()
            controller:setOnOff(true)
        end)
        setPatrolAlarmState(controller)
        setGroundROE(controller, true)
    end
    element.aiState = false
    if element.targetsInRange ~= nil then
        element.targetsInRange = false
    end
    element.cachedTargets = {}
    if element.stopScanningForHARMs then
        element:stopScanningForHARMs()
    end
end

local function setCombatROEForRepresentation(representation, weaponHold)
    if representation == nil or representation.isExist == nil or representation:isExist() == false then
        return
    end
    local okController, controller = pcall(function()
        return representation:getController()
    end)
    if okController and controller then
        pcall(function()
            controller:setOnOff(true)
        end)
        setCombatAlarmState(controller)
        setGroundROE(controller, weaponHold)
        pcall(function()
            representation:enableEmission(true)
        end)
    end
end

local function setElementCombatROE(element, weaponHold)
    if element == nil or element.isDestroyed == nil or element:isDestroyed() then
        return
    end
    local representations = collectElementEmitterRepresentations(element)
    for i = 1, #representations do
        setCombatROEForRepresentation(representations[i], weaponHold)
    end
    local controller = element.getController and element:getController() or nil
    if controller then
        pcall(function()
            controller:setOnOff(true)
        end)
        setCombatAlarmState(controller)
        setGroundROE(controller, weaponHold)
    end
    if weaponHold then
        element.aiState = true
    end
end

function SkynetIADSSiblingCoordination.getFamilyForElement(element)
    local family = SkynetIADSSiblingCoordination._familyByElement[element]
    local member = SkynetIADSSiblingCoordination._memberByElement[element]
    if family == nil or member == nil then
        return nil
    end
    return {
        name = family.name,
        mode = family.mode,
        role = member.lastRole or "released",
        primaryGroupName = family.activeGroupName,
        preferredPrimaryGroupName = family.preferredPrimaryGroupName,
        denialAlertDistanceNm = family.denialAlertDistanceNm,
        reason = family.activeReason,
        passiveAction = family.passiveAction,
        passiveMode = member.passiveMode,
    }
end

function SkynetIADSSiblingCoordination.isElementForcedPassive(element)
    local member = SkynetIADSSiblingCoordination._memberByElement[element]
    return member ~= nil and member.forcedPassive == true
end

function SkynetIADSSiblingCoordination:log(message)
    if self.iads and self.iads.printOutputToLog then
        self.iads:printOutputToLog("[SiblingCoord] " .. message)
    end
end

function SkynetIADSSiblingCoordination:notifyDebug(message)
    if _G.SkynetRuntimeDebugNotify and message then
        pcall(_G.SkynetRuntimeDebugNotify, message)
    end
end

function SkynetIADSSiblingCoordination:getMobilePatrolEntry(element)
    if SkynetIADSMobilePatrol and SkynetIADSMobilePatrol.getEntryForElement then
        return SkynetIADSMobilePatrol.getEntryForElement(element)
    end
    return nil
end

function SkynetIADSSiblingCoordination:isSuppressed(member)
    local element = member.element
    return element.harmSilenceID ~= nil or element.harmRelocationInProgress == true
end

function SkynetIADSSiblingCoordination:isEngaged(member)
    local element = member.element
    local entry = self:getMobilePatrolEntry(element)
    if entry ~= nil then
        if entry.manager and entry.manager.isMoveFireCapable and entry.manager:isMoveFireCapable(entry) == true then
            return (
                (entry.combatMode ~= nil and entry.combatMode ~= "patrolling" and entry.combatMode ~= "searching")
                or element.targetsInRange == true
                or element:getNumberOfMissilesInFlight() > 0
            )
        end
        return (
            entry.combatCommitted == true
            or element.targetsInRange == true
            or element:isActive()
            or element:getNumberOfMissilesInFlight() > 0
        )
    end
    return element:isActive() or element.targetsInRange == true or element:getNumberOfMissilesInFlight() > 0
end

function SkynetIADSSiblingCoordination:canCover(member)
    local element = member.element
    return element:isDestroyed() == false
        and element:hasWorkingPowerSource()
        and element:hasRemainingAmmo()
        and element:hasWorkingRadar()
end

function SkynetIADSSiblingCoordination:findMemberByGroupName(family, groupName)
    for i = 1, #family.members do
        local member = family.members[i]
        if member.groupName == groupName then
            return member
        end
    end
    return nil
end

function SkynetIADSSiblingCoordination:pickCoverMember(family, excludedGroupName)
    for i = 1, #family.members do
        local member = family.members[i]
        if member.groupName ~= excludedGroupName and self:isSuppressed(member) == false and self:canCover(member) then
            return member
        end
    end
    return nil
end

function SkynetIADSSiblingCoordination:getPreferredPrimaryMember(family)
    if family.preferredPrimaryGroupName then
        local preferred = self:findMemberByGroupName(family, family.preferredPrimaryGroupName)
        if preferred then
            return preferred
        end
    end
    return family.members[1]
end

function SkynetIADSSiblingCoordination:getBestAmbushThreatCandidate(family)
    local bestMember = nil
    local bestDecision = nil
    local bestShouldGoLive = -1
    local bestDistanceNm = math.huge
    local bestPreferred = -1
    for i = 1, #family.members do
        local member = family.members[i]
        if self:isSuppressed(member) == false and self:canCover(member) then
            local entry = self:getMobilePatrolEntry(member.element)
            if entry and entry.kind == "MSAM" and entry.manager and entry.manager.findSAMThreatContact then
                local threatDecision = entry.manager:findSAMThreatContact(entry)
                if threatDecision then
                    local triggerInfo = threatDecision.triggerInfo or {}
                    local shouldGoLiveScore = threatDecision.shouldGoLive == true and 1 or 0
                    local distanceNm = tonumber(triggerInfo.distanceNm) or math.huge
                    local preferredScore = family.preferredPrimaryGroupName == member.groupName and 1 or 0
                    local isBetter =
                        shouldGoLiveScore > bestShouldGoLive
                        or (shouldGoLiveScore == bestShouldGoLive and distanceNm < bestDistanceNm)
                        or (shouldGoLiveScore == bestShouldGoLive and distanceNm == bestDistanceNm and preferredScore > bestPreferred)
                    if isBetter then
                        bestMember = member
                        bestDecision = threatDecision
                        bestShouldGoLive = shouldGoLiveScore
                        bestDistanceNm = distanceNm
                        bestPreferred = preferredScore
                    end
                end
            end
        end
    end
    return bestMember, bestDecision
end

function SkynetIADSSiblingCoordination:arbitrateThreatDecision(element)
    local family = SkynetIADSSiblingCoordination._familyByElement[element]
    local member = SkynetIADSSiblingCoordination._memberByElement[element]
    if family == nil or member == nil then
        return nil, true
    end
    if member.forcedPassive == true then
        return nil, false
    end

    local currentPrimary = self:findMemberByGroupName(family, family.activeGroupName)
    if currentPrimary and self:isSuppressed(currentPrimary) == false and self:isEngaged(currentPrimary) then
        if currentPrimary ~= member then
            return nil, false
        end
        if family.mode == "denial" then
            local denialThreatDecision = self:getDenialThreatDecision(family, currentPrimary)
            if denialThreatDecision then
                return denialThreatDecision, true
            end
        end
        local entry = self:getMobilePatrolEntry(member.element)
        if entry and entry.kind == "MSAM" and entry.manager and entry.manager.findSAMThreatContact then
            return entry.manager:findSAMThreatContact(entry), true
        end
        return nil, true
    end

    if family.mode == "denial" then
        local preferredPrimary = self:getPreferredPrimaryMember(family)
        if preferredPrimary ~= member or self:isSuppressed(preferredPrimary) or self:canCover(preferredPrimary) == false then
            return nil, false
        end
        return self:getDenialThreatDecision(family, preferredPrimary), true
    end

    if family.mode == "ambush" then
        local preferredPrimary = self:getPreferredPrimaryMember(family)
        if preferredPrimary and self:isSuppressed(preferredPrimary) == false and self:canCover(preferredPrimary) then
            local preferredEntry = self:getMobilePatrolEntry(preferredPrimary.element)
            if preferredEntry and preferredEntry.kind == "MSAM" and preferredEntry.manager and preferredEntry.manager.findSAMThreatContact then
                local preferredDecision = preferredEntry.manager:findSAMThreatContact(preferredEntry)
                if preferredDecision then
                    if preferredPrimary ~= member then
                        return nil, false
                    end
                    return preferredDecision, true
                end
            end
        end
    end

    local bestMember, bestDecision = self:getBestAmbushThreatCandidate(family)
    if bestMember == nil then
        return nil, true
    end
    if bestMember ~= member then
        return nil, false
    end
    return bestDecision, true
end

function SkynetIADSSiblingCoordination:getDenialThreatDecision(family, member)
    local entry = self:getMobilePatrolEntry(member.element)
    if entry == nil or entry.kind ~= "MSAM" or entry.manager == nil then
        return nil
    end
    local moveFireCapable = entry.manager.isMoveFireCapable and entry.manager:isMoveFireCapable(entry) == true
    local alertRangeMeters = mist.utils.NMToMeters(family.denialAlertDistanceNm or self.defaultDenialAlertDistanceNm)
    local directUnit = nil
    local directUnitDistanceMeters = math.huge
    if entry.manager.findNearestEnemyAircraftUnit then
        directUnit, directUnitDistanceMeters = entry.manager:findNearestEnemyAircraftUnit(entry, alertRangeMeters)
    end

    local contact = nil
    local contactDistanceMeters = math.huge
    if entry.manager.findNearestEligibleContact then
        contact, contactDistanceMeters = entry.manager:findNearestEligibleContact(entry, alertRangeMeters)
    end

    if directUnit == nil and contact == nil then
        return nil
    end

    local canGoLive = moveFireCapable or contact ~= nil
    local combatMode = canGoLive and "sibling_denial_alert" or "sibling_denial_deploy"
    local triggerInfo = nil
    if directUnit ~= nil and entry.manager.buildAircraftUnitTriggerInfo then
        triggerInfo = entry.manager:buildAircraftUnitTriggerInfo(entry, directUnit, "sibling_denial_alert", alertRangeMeters)
    else
        triggerInfo = entry.manager:buildDeployTriggerInfo(entry, contact, "sibling_denial_alert")
        triggerInfo.distanceNm = mist.utils.round(mist.utils.metersToNM(contactDistanceMeters), 1)
    end

    triggerInfo.combatMode = combatMode
    triggerInfo.familyMode = family.mode
    triggerInfo.denialAlertDistanceNm = family.denialAlertDistanceNm or self.defaultDenialAlertDistanceNm
    triggerInfo.engageRangeNm = mist.utils.round(mist.utils.metersToNM(alertRangeMeters), 1)
    if contact ~= nil and contactDistanceMeters < math.huge then
        triggerInfo.contactDistanceNm = mist.utils.round(mist.utils.metersToNM(contactDistanceMeters), 1)
    end
    if directUnit ~= nil and directUnitDistanceMeters < math.huge then
        triggerInfo.directDistanceNm = mist.utils.round(mist.utils.metersToNM(directUnitDistanceMeters), 1)
        triggerInfo.effectiveDistanceNm = triggerInfo.directDistanceNm
        triggerInfo.distanceNm = triggerInfo.directDistanceNm
    elseif contactDistanceMeters < math.huge then
        triggerInfo.effectiveDistanceNm = mist.utils.round(mist.utils.metersToNM(contactDistanceMeters), 1)
        triggerInfo.distanceNm = triggerInfo.contactDistanceNm or triggerInfo.distanceNm
    end

    return {
        contact = contact,
        triggerInfo = triggerInfo,
        shouldDeploy = not moveFireCapable,
        shouldGoLive = canGoLive,
        shouldWeaponHold = false,
        combatMode = combatMode,
    }
end

function SkynetIADSSiblingCoordination:choosePrimaryMember(family)
    local currentPrimary = self:findMemberByGroupName(family, family.activeGroupName)
    if currentPrimary and self:isSuppressed(currentPrimary) == false and self:isEngaged(currentPrimary) then
        return currentPrimary, "engaged", nil
    end

    if currentPrimary and self:isSuppressed(currentPrimary) then
        local coverMember = self:pickCoverMember(family, currentPrimary.groupName)
        if coverMember then
            return coverMember, "cover_for_" .. currentPrimary.groupName, nil
        end
    end

    if family.mode == "denial" then
        local preferredPrimary = self:getPreferredPrimaryMember(family)
        if preferredPrimary and self:isSuppressed(preferredPrimary) == false and self:canCover(preferredPrimary) then
            local denialThreatDecision = self:getDenialThreatDecision(family, preferredPrimary)
            if denialThreatDecision then
                return preferredPrimary, "denial_trigger", denialThreatDecision
            end
        end
        if preferredPrimary and self:isSuppressed(preferredPrimary) then
            local coverMember = self:pickCoverMember(family, preferredPrimary.groupName)
            if coverMember then
                return coverMember, "cover_for_" .. preferredPrimary.groupName, nil
            end
        end
    end

    if family.mode == "ambush" then
        local preferredPrimary = self:getPreferredPrimaryMember(family)
        if preferredPrimary and self:isSuppressed(preferredPrimary) == false and self:canCover(preferredPrimary) then
            local preferredEntry = self:getMobilePatrolEntry(preferredPrimary.element)
            if preferredEntry and preferredEntry.kind == "MSAM" and preferredEntry.manager and preferredEntry.manager.findSAMThreatContact then
                local preferredDecision = preferredEntry.manager:findSAMThreatContact(preferredEntry)
                if preferredDecision then
                    return preferredPrimary, "preferred_trigger", preferredDecision
                end
            end
        end
        if preferredPrimary and self:isSuppressed(preferredPrimary) then
            local coverMember = self:pickCoverMember(family, preferredPrimary.groupName)
            if coverMember then
                return coverMember, "cover_for_" .. preferredPrimary.groupName, nil
            end
        end
    end

    for i = 1, #family.members do
        local member = family.members[i]
        if self:isSuppressed(member) == false and self:isEngaged(member) then
            return member, "engaged", nil
        end
    end

    for i = 1, #family.members do
        local member = family.members[i]
        if self:isSuppressed(member) then
            local coverMember = self:pickCoverMember(family, member.groupName)
            if coverMember then
                return coverMember, "cover_for_" .. member.groupName, nil
            end
        end
    end

    return nil, nil, nil
end

function SkynetIADSSiblingCoordination:activateMember(family, member, reason, threatDecision)
    if self:isSuppressed(member) then
        return
    end
    local switchedPrimary = family.activeGroupName ~= member.groupName or family.activeReason ~= reason
    member.forcedPassive = false
    member.passiveMode = nil
    member.lastRole = "primary"
    local entry = self:getMobilePatrolEntry(member.element)
    local moveFireCapable = entry and entry.manager and entry.manager.isMoveFireCapable and entry.manager:isMoveFireCapable(entry) == true
    local shouldForceDeploy = reason ~= nil and string.find(reason, "cover_for_", 1, true) == 1
    if entry and entry.combatCommitted == true and shouldForceDeploy ~= true and reason == "engaged" then
        if switchedPrimary then
            self:log("Primary active | family=" .. family.name .. " | group=" .. member.groupName .. " | reason=" .. tostring(reason))
            self:notifyDebug(family.name .. " 主战切换 -> " .. member.groupName .. " | reason=" .. tostring(reason))
        end
        family.activeGroupName = member.groupName
        family.activeReason = reason
        return
    end
    if entry and entry.manager and entry.manager.applyMSAMThreatDecision then
        if threatDecision == nil and entry.manager.findSAMThreatContact then
            threatDecision = entry.manager:findSAMThreatContact(entry)
        end
        if threatDecision == nil and shouldForceDeploy ~= true then
            if switchedPrimary then
                self:log("Primary active | family=" .. family.name .. " | group=" .. member.groupName .. " | reason=" .. tostring(reason))
                self:notifyDebug(family.name .. " 涓绘垬鍒囨崲 -> " .. member.groupName .. " | reason=" .. tostring(reason))
            end
            family.activeGroupName = member.groupName
            family.activeReason = reason
            return
        end
        if threatDecision == nil then
            local preferredTargetName = family.activeGroupName or family.name
            if entry.lastDeployTrigger and entry.lastDeployTrigger.contactName then
                preferredTargetName = entry.lastDeployTrigger.contactName
            end
            local syntheticTriggerInfo = entry.lastDeployTrigger and mist.utils.deepCopy(entry.lastDeployTrigger) or nil
            if syntheticTriggerInfo == nil and entry.manager.findSAMThreatContact then
                local inferredThreatDecision = entry.manager:findSAMThreatContact(entry)
                if inferredThreatDecision and inferredThreatDecision.triggerInfo then
                    syntheticTriggerInfo = mist.utils.deepCopy(inferredThreatDecision.triggerInfo)
                end
            end
            threatDecision = {
                shouldDeploy = moveFireCapable ~= true,
                shouldGoLive = true,
                shouldWeaponHold = false,
                combatMode = shouldForceDeploy and "sibling_cover" or "sibling_primary",
                triggerInfo = syntheticTriggerInfo or {
                    source = "sibling_coord",
                    contactName = preferredTargetName,
                    contactType = shouldForceDeploy and "sibling_cover" or "sibling_primary",
                    time = timer.getTime(),
                    combatMode = shouldForceDeploy and "sibling_cover" or "sibling_primary",
                },
            }
            threatDecision.triggerInfo.source = threatDecision.triggerInfo.source or "sibling_coord"
            threatDecision.triggerInfo.contactName = threatDecision.triggerInfo.contactName or preferredTargetName
            threatDecision.triggerInfo.contactType = threatDecision.triggerInfo.contactType or (shouldForceDeploy and "sibling_cover" or "sibling_primary")
            threatDecision.triggerInfo.combatMode = shouldForceDeploy and "sibling_cover" or "sibling_primary"
        end
        entry.manager:applyMSAMThreatDecision(entry, threatDecision)
    else
        if shouldForceDeploy and moveFireCapable ~= true and entry and entry.state == "patrolling" and entry.manager and entry.manager.pausePatrolForDeployment then
            entry.manager:pausePatrolForDeployment(entry, {
                source = "sibling_coord",
                contactName = family.activeGroupName or "sibling",
                contactType = "sibling_cover",
                distanceNm = 0,
                threatRangeNm = 0,
                time = timer.getTime(),
                combatMode = "sibling_cover",
            })
        end
        if member.element.targetsInRange ~= nil then
            member.element.targetsInRange = true
        end
        member.element:goLive()
        setElementCombatROE(member.element, false)
    end
    if switchedPrimary then
        self:log("Primary active | family=" .. family.name .. " | group=" .. member.groupName .. " | reason=" .. tostring(reason))
        self:notifyDebug(family.name .. " 主战切换 -> " .. member.groupName .. " | reason=" .. tostring(reason))
    end
    family.activeGroupName = member.groupName
    family.activeReason = reason
end

function SkynetIADSSiblingCoordination:setPassiveMember(family, member)
    local previousPassiveMode = member.passiveMode
    if self:isSuppressed(member) then
        member.lastRole = "suppressed"
        member.passiveMode = "suppressed"
        if previousPassiveMode ~= "suppressed" then
            self:notifyDebug(member.groupName .. " 受压制待机 | family=" .. family.name)
        end
        return
    end
    local previousRole = member.lastRole
    member.forcedPassive = true
    member.lastRole = "passive"
    local entry = self:getMobilePatrolEntry(member.element)
    if family.passiveAction == "relocate" and entry and entry.kind == "MSAM" then
        if entry.manager and entry.manager.isMoveFireCapable and entry.manager:isMoveFireCapable(entry) == true then
            member.passiveMode = "relocate"
            if entry.state ~= "patrolling" then
                entry.manager:beginPatrol(entry)
            end
            if previousPassiveMode ~= "relocate" then
                self:notifyDebug(member.groupName .. " 转移待机 | family=" .. family.name)
            end
            return
        end
        if previousRole == "primary" or previousRole == "suppressed" then
            member.passiveMode = "relocate"
            if entry.manager and entry.manager.beginPatrol and entry.state ~= "patrolling" then
                entry.manager:beginPatrol(entry)
            end
            if previousPassiveMode ~= "relocate" then
                self:notifyDebug(member.groupName .. " 转移待机 | family=" .. family.name)
            end
            return
        end
        member.passiveMode = "standby"
        if entry.state == "patrolling" and entry.manager and entry.manager.pausePatrolForDeployment then
            entry.manager:pausePatrolForDeployment(entry, {
                source = "sibling_coord",
                contactName = family.activeGroupName or "sibling",
                contactType = "sibling_standby",
                distanceNm = 0,
                threatRangeNm = 0,
                time = timer.getTime(),
                combatMode = "sibling_standby",
            })
        end
        forceElementIntoDarkStandby(member.element)
        if previousPassiveMode ~= "standby" then
            self:notifyDebug(member.groupName .. " 部署待机 | family=" .. family.name)
        end
        return
    end
    if family.passiveAction == "relocate" and entry and entry.manager and entry.manager.beginPatrol then
        member.passiveMode = "relocate"
        if entry.state ~= "patrolling" then
            entry.manager:beginPatrol(entry)
        end
        if previousPassiveMode ~= "relocate" then
            self:notifyDebug(member.groupName .. " 转移待机 | family=" .. family.name)
        end
        return
    end
    member.passiveMode = "hold_dark"
    if entry and entry.manager and entry.manager.issueHold then
        entry.manager:issueHold(entry)
    end
    forceElementIntoDarkStandby(member.element)
    if previousPassiveMode ~= "hold_dark" then
        self:notifyDebug(member.groupName .. " 黑灯待命 | family=" .. family.name)
    end
end

function SkynetIADSSiblingCoordination:releaseMember(member)
    local previousRole = member.lastRole
    member.forcedPassive = false
    member.passiveMode = nil
    member.lastRole = "released"
    if self:isSuppressed(member) then
        return
    end
    local entry = self:getMobilePatrolEntry(member.element)
    if entry and entry.manager and entry.manager.beginPatrol and entry.kind == "MSAM" then
        if entry.state ~= "patrolling" then
            entry.manager:beginPatrol(entry)
        end
        if previousRole ~= "released" then
            self:notifyDebug(member.groupName .. " 解除兄弟约束")
        end
        return
    end
    if member.element.setToCorrectAutonomousState then
        member.element:setToCorrectAutonomousState()
    else
        member.element:goDark()
    end
    if previousRole ~= "released" then
        self:notifyDebug(member.groupName .. " 解除兄弟约束")
    end
end

function SkynetIADSSiblingCoordination:updateFamily(family)
    local primary, reason, threatDecision = self:choosePrimaryMember(family)
    if primary then
        for i = 1, #family.members do
            local member = family.members[i]
            if member == primary then
                self:activateMember(family, member, reason, threatDecision)
            else
                self:setPassiveMember(family, member)
            end
        end
        return
    end

    if family.activeGroupName ~= nil then
        self:log("Family released | family=" .. family.name)
    end
    family.activeGroupName = nil
    family.activeReason = nil
    for i = 1, #family.members do
        self:releaseMember(family.members[i])
    end
end

function SkynetIADSSiblingCoordination:tick(_, time)
    for i = 1, #self.families do
        self:updateFamily(self.families[i])
    end
    return time + self.checkInterval
end

function SkynetIADSSiblingCoordination:requestImmediateEvaluation(reason)
    if self._immediateEvaluationInProgress == true or #self.families == 0 then
        return
    end
    self._immediateEvaluationInProgress = true
    for i = 1, #self.families do
        self:updateFamily(self.families[i])
    end
    self._immediateEvaluationInProgress = false
    if reason then
        self:log("immediate evaluation | reason=" .. tostring(reason))
    end
end

function SkynetIADSSiblingCoordination:start()
    if self.taskID ~= nil or #self.families == 0 then
        return
    end
    self.taskID = mist.scheduleFunction(
        SkynetIADSSiblingCoordination.tick,
        { self = self },
        timer.getTime() + self.checkInterval,
        self.checkInterval
    )
    self:log("started | families=" .. tostring(#self.families) .. " | interval=" .. tostring(self.checkInterval) .. "s")
end

function SkynetIADSSiblingCoordination:registerFamily(definition)
    if definition == nil or definition.members == nil or #definition.members < 2 then
        return false, 0
    end
    local family = {
        name = definition.name or ("SiblingFamily-" .. tostring(#self.families + 1)),
        mode = definition.mode or self.defaultMode,
        passiveAction = definition.passiveAction or self.defaultPassiveAction,
        preferredPrimaryGroupName = definition.primary,
        denialAlertDistanceNm = definition.denialAlertDistanceNm or self.defaultDenialAlertDistanceNm,
        members = {},
        activeGroupName = nil,
        activeReason = nil,
    }

    for i = 1, #definition.members do
        local groupName = definition.members[i]
        local samSite = self.iads:getSAMSiteByGroupName(groupName)
        if samSite then
            local member = {
                groupName = groupName,
                element = samSite,
                family = family,
                forcedPassive = false,
                lastRole = "released",
            }
            family.members[#family.members + 1] = member
            SkynetIADSSiblingCoordination._familyByElement[samSite] = family
            SkynetIADSSiblingCoordination._memberByElement[samSite] = member
        else
            self:log("register skipped | family=" .. family.name .. " | missing group=" .. tostring(groupName))
        end
    end

    if #family.members < 2 then
        self:log("register ignored | family=" .. family.name .. " | not enough valid members")
        return false, #family.members
    end

    self.families[#self.families + 1] = family
    if family.preferredPrimaryGroupName == nil and #family.members > 0 then
        family.preferredPrimaryGroupName = family.members[1].groupName
    end

    self:log(
        "registered | family=" .. family.name
        .. " | mode=" .. tostring(family.mode)
        .. " | preferredPrimary=" .. tostring(family.preferredPrimaryGroupName)
        .. " | members=" .. tostring(#family.members)
        .. " | passiveAction=" .. tostring(family.passiveAction)
    )
    return true, #family.members
end

function SkynetIADSSiblingCoordination:registerFamilies(definitions)
    local registeredFamilies = 0
    local registeredMembers = 0
    if definitions == nil then
        return registeredFamilies, registeredMembers
    end
    for i = 1, #definitions do
        local ok, memberCount = self:registerFamily(definitions[i])
        if ok then
            registeredFamilies = registeredFamilies + 1
            registeredMembers = registeredMembers + memberCount
        end
    end
    return registeredFamilies, registeredMembers
end

function SkynetIADSSiblingCoordination.create(iads, config)
    local self = {}
    setmetatable(self, SkynetIADSSiblingCoordination)
    self.iads = iads
    self.checkInterval = (config and config.checkInterval) or SkynetIADSSiblingCoordination.DEFAULT_CHECK_INTERVAL
    self.defaultPassiveAction = (config and config.defaultPassiveAction) or SkynetIADSSiblingCoordination.DEFAULT_PASSIVE_ACTION
    self.defaultMode = (config and config.defaultMode) or SkynetIADSSiblingCoordination.DEFAULT_MODE
    self.defaultDenialAlertDistanceNm = (config and config.defaultDenialAlertDistanceNm) or SkynetIADSSiblingCoordination.DEFAULT_DENIAL_ALERT_DISTANCE_NM
    self.families = {}
    self.taskID = nil
    self._immediateEvaluationInProgress = false
    return self
end

trigger.action.outText("Skynet Sibling Coordination module loaded", 10)

end


do

SkynetIADSEWRReporter = {}

local function normalizeHeading(deg)
    deg = deg % 360
    if deg < 0 then
        deg = deg + 360
    end
    return deg
end

local function normalizeDelta(delta)
    while delta > 180 do
        delta = delta - 360
    end
    while delta < -180 do
        delta = delta + 360
    end
    return delta
end

local function objectExists(obj)
    return obj and obj.isExist and obj:isExist()
end

local function get2dHeadingDeg(fromPoint, toPoint)
    local dx = toPoint.x - fromPoint.x
    local dz = toPoint.z - fromPoint.z
    if math.abs(dx) < 0.001 and math.abs(dz) < 0.001 then
        return 0
    end
    return normalizeHeading(math.deg(math.atan2(dx, dz)))
end

local function get2dDistanceMeters(fromPoint, toPoint)
    local dx = toPoint.x - fromPoint.x
    local dz = toPoint.z - fromPoint.z
    return math.sqrt(dx * dx + dz * dz)
end

local function getContactPoint(contact)
    if contact and contact.getPosition then
        local position = contact:getPosition()
        if position and position.p then
            return position.p
        end
    end
    local obj = contact and contact.getDCSRepresentation and contact:getDCSRepresentation() or nil
    if objectExists(obj) and obj.getPoint then
        return obj:getPoint()
    end
    return nil
end

local function isAirContact(contact)
    if not contact or not contact.getDesc then
        return false
    end
    local desc = contact:getDesc() or {}
    local category = desc.category
    return category == Unit.Category.AIRPLANE or category == Unit.Category.HELICOPTER
end

local function isPlayerAircraft(unit)
    if not objectExists(unit) then
        return false
    end
    local desc = unit:getDesc() or {}
    local category = desc.category
    return category == Unit.Category.AIRPLANE or category == Unit.Category.HELICOPTER
end

local function getContactDisplayType(contact)
    local typeName = contact and contact.getTypeName and contact:getTypeName() or "UNKNOWN"
    if typeName == nil or typeName == "" then
        typeName = "UNKNOWN"
    end
    return typeName
end

local function getContactHeadingDeg(contact)
    if not contact or not contact.getMagneticHeading then
        return 0
    end
    local heading = contact:getMagneticHeading()
    if heading == nil or heading < 0 then
        return 0
    end
    return normalizeHeading(heading)
end

local function getContactAltitudeAngels(contact)
    local feet = contact and contact.getHeightInFeetMSL and contact:getHeightInFeetMSL() or 0
    return math.max(0, math.floor((feet / 1000.0) + 0.5))
end

local function getAspectLabel(contactHeadingDeg, targetToPlayerHeadingDeg)
    local delta = normalizeDelta(contactHeadingDeg - targetToPlayerHeadingDeg)
    local absDelta = math.abs(delta)
    if absDelta <= 45 then
        return "HOT"
    end
    if absDelta >= 135 then
        return "COLD"
    end
    if delta > 0 then
        return "FLANK RIGHT"
    end
    return "FLANK LEFT"
end

function SkynetIADSEWRReporter:create(iads, options)
    local instance = {}
    setmetatable(instance, self)
    self.__index = self

    instance.iads = iads
    instance.intervalSeconds = (options and options.intervalSeconds) or 15
    instance.messageDurationSeconds = (options and options.messageDurationSeconds) or 8
    instance.maxContactsPerPlayer = (options and options.maxContactsPerPlayer) or 3
    instance.reportClean = (options and options.reportClean) == true
    instance.debugAllPlayers = (options and options.debugAllPlayers) == true
    instance.taskID = nil
    instance.lastSummaryByGroup = {}
    return instance
end

function SkynetIADSEWRReporter:getCoalition()
    if self.iads and self.iads.getCoalition then
        return self.iads:getCoalition()
    end
    return nil
end

function SkynetIADSEWRReporter:collectPlayerRecipients()
    local recipientsByGroup = {}
    local coalitionIds = {}
    if self.debugAllPlayers then
        coalitionIds = {
            coalition.side.RED,
            coalition.side.BLUE,
        }
    else
        local coalitionId = self:getCoalition()
        if coalitionId == nil then
            return {}
        end
        coalitionIds = { coalitionId }
    end

    for coalitionIndex = 1, #coalitionIds do
        local players = coalition.getPlayers(coalitionIds[coalitionIndex]) or {}
        for i = 1, #players do
            local unit = players[i]
            if isPlayerAircraft(unit) then
                local group = unit:getGroup()
                if group and group:isExist() then
                    local groupId = group:getID()
                    if recipientsByGroup[groupId] == nil then
                        recipientsByGroup[groupId] = {
                            groupId = groupId,
                            unit = unit
                        }
                    end
                end
            end
        end
    end

    local recipients = {}
    for _, recipient in pairs(recipientsByGroup) do
        table.insert(recipients, recipient)
    end
    return recipients
end

function SkynetIADSEWRReporter:collectReportableContacts()
    local contacts = self.iads and self.iads.getContacts and self.iads:getContacts() or {}
    local filtered = {}
    for i = 1, #contacts do
        local contact = contacts[i]
        if isAirContact(contact) and contact:isExist() and contact:isIdentifiedAsHARM() == false then
            table.insert(filtered, contact)
        end
    end
    return filtered
end

function SkynetIADSEWRReporter:formatContactLine(playerUnit, contact)
    local playerPos = playerUnit:getPoint()
    local contactPos = getContactPoint(contact)
    if not playerPos or not contactPos then
        return nil
    end

    local bearingDeg = get2dHeadingDeg(playerPos, contactPos)
    local distanceNm = mist.utils.metersToNM(get2dDistanceMeters(playerPos, contactPos))
    local contactHeadingDeg = getContactHeadingDeg(contact)
    local targetToPlayerHeadingDeg = get2dHeadingDeg(contactPos, playerPos)
    local aspectLabel = getAspectLabel(contactHeadingDeg, targetToPlayerHeadingDeg)
    local angels = getContactAltitudeAngels(contact)

    return string.format(
        "%s | A%d | Hdg %03d | BRAA %03d/%d | %s",
        getContactDisplayType(contact),
        angels,
        contactHeadingDeg,
        bearingDeg,
        math.floor(distanceNm + 0.5),
        aspectLabel
    ), distanceNm
end

function SkynetIADSEWRReporter:buildMessageForPlayer(playerUnit, contacts)
    local entries = {}
    for i = 1, #contacts do
        local line, distanceNm = self:formatContactLine(playerUnit, contacts[i])
        if line ~= nil then
            table.insert(entries, {
                line = line,
                distanceNm = distanceNm
            })
        end
    end

    table.sort(entries, function(a, b)
        return (a.distanceNm or math.huge) < (b.distanceNm or math.huge)
    end)

    if #entries == 0 then
        if self.reportClean then
            return "EWR Picture | CLEAN"
        end
        return nil
    end

    local lines = {"EWR Picture"}
    local limit = math.min(self.maxContactsPerPlayer, #entries)
    for i = 1, limit do
        lines[#lines + 1] = tostring(i) .. ". " .. entries[i].line
    end
    if #entries > limit then
        lines[#lines + 1] = string.format("+%d more", #entries - limit)
    end
    return table.concat(lines, "\n")
end

function SkynetIADSEWRReporter:broadcastTick()
    local contacts = self:collectReportableContacts()
    local recipients = self:collectPlayerRecipients()

    for i = 1, #recipients do
        local recipient = recipients[i]
        local message = self:buildMessageForPlayer(recipient.unit, contacts)
        if message ~= nil then
            trigger.action.outTextForGroup(recipient.groupId, message, self.messageDurationSeconds)
            self.lastSummaryByGroup[recipient.groupId] = message
        end
    end
end

function SkynetIADSEWRReporter._tick(params, time)
    local self = params.self
    if not self or not self.iads then
        return nil
    end
    self:broadcastTick()
    return time + self.intervalSeconds
end

function SkynetIADSEWRReporter:start()
    if self.taskID ~= nil then
        return
    end
    self.taskID = mist.scheduleFunction(
        SkynetIADSEWRReporter._tick,
        {self = self},
        timer.getTime() + self.intervalSeconds,
        self.intervalSeconds
    )
    if self.iads and self.iads.printOutputToLog then
        self.iads:printOutputToLog("[EWRReporter] started | interval=" .. tostring(self.intervalSeconds) .. "s | topN=" .. tostring(self.maxContactsPerPlayer) .. " | debugAllPlayers=" .. tostring(self.debugAllPlayers))
    end
end

function SkynetIADSEWRReporter:stop()
    if self.taskID ~= nil then
        mist.removeFunction(self.taskID)
        self.taskID = nil
    end
end

trigger.action.outText("Skynet EWR Reporter module loaded", 10)

end
