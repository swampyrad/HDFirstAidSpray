enum MediSprayNums{
	FIRSTAID_FLESHGIVE=5,
	FIRSTAID_MAXFLESH=14,//about 3 doses worth
	FIRSTAID_NOTAPLAYER=MAXPLAYERS+1,

	MEDSPRAY_SECONDFLESH=1,
	MEDSPRAY_USEDON=2,
	MEDSPRAY_ACCURACY=3,
	MEDSPRAY_BLOOD=4,

/*
	CHECKCOV_ONLYFULL=1,
	CHECKCOV_CHECKBODY=2,
	CHECKCOV_CHECKFACE=4,
*/
}

class FirstAid_Spawner : EventHandler
{
override void CheckReplacement(ReplaceEvent e) {
	switch (e.Replacee.GetClassName()) {

  	case 'BlueFrag' 			: if (!random(0, 11)) {e.Replacement = "HDFirstAidSprayer";} break;
  	case 'HelmFrag' 			: if (!random(0, 15)) {e.Replacement = "HDFirstAidSprayer";} break;
  	case 'Stimpack' 			: if (!random(0, 15)) {e.Replacement = "HDFirstAidSprayer";} break;

		}

	e.IsFinal = false;
	}
}

class HDFirstAidSprayer :HDWoundFixer{
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}
	default{
		-weapon.no_auto_switch
		+hdweapon.fitsinbackpack
		
		-weapon.cheatnotweapon
		//adding this made it backpackable

		+inventory.ishealth
		+inventory.invbar
		-nointeraction
		weapon.selectionorder 1001;
		weapon.slotnumber 9;
		scale 0.3;
		tag "First Aid Spray";
		hdweapon.refid "aid";

		hdweapon.wornlayer 0;
	}

	override void initializewepstats(bool idfa){
		weaponstatus[MEDSPRAY_SECONDFLESH] = FIRSTAID_MAXFLESH;
		weaponstatus[MEDSPRAY_USEDON]=-1;
		patientname="** UNKNOWN **";
	}

	override double weaponbulk(){
		return ENC_MEDIKIT/3;
	}

	override string,double getpickupsprite(){
		return (weaponstatus[MEDSPRAY_SECONDFLESH]<1)?"FAIDC0":"FAIDB0",0.6;
	}

	string patientname;

	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		let ww=HDFirstAidSprayer(hdw);
		int of=0;
		let bwnd=hdbleedingwound.findbiggest(hpl);
	
/*	
		if(
			bwnd
			&&(weaponstatus[MEDSPRAY_USEDON]<0||weaponstatus[MEDSPRAY_USEDON]==hpl.playernumber())
		){
			of=clamp(int(bwnd.width*0.1),1,3);
			if(hpl.flip)of=-of;
		}
*/

		sb.drawrect(-29,-17+of,2,6);
		sb.drawrect(-31,-15+of,6,2);

		int usedon=weaponstatus[MEDSPRAY_USEDON];


		if(usedon>=0){
			int upn=weaponstatus[MEDSPRAY_USEDON];
			string pn=
				upn>=0
				&&upn<MAXPLAYERS
				&&playeringame[upn]
				?players[upn].getusername()
				:patientname
			;

/*
			sb.DrawString(sb.psmallfont,pn,(-53,-8),
				sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_RIGHT|sb.DI_TEXT_ALIGN_RIGHT,
				Font.CR_RED,scale:(0.3,0.5)
			);
*/

			sb.drawimage(
				"BLUDB0",(-7,-12),
				sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_VCENTER|sb.DI_ITEM_RIGHT,
				0.2+min(0.4,0.01*ww.weaponstatus[MEDSPRAY_BLOOD]),scale:(1.5,1.5)*(1+0.02*ww.weaponstatus[MEDSPRAY_BLOOD])
			);
		}

		int btn=hpl.player.cmd.buttons;

		if(!(btn&BT_FIREMODE)){
			sb.drawwepnum(ww.weaponstatus[MEDSPRAY_SECONDFLESH],FIRSTAID_MAXFLESH);

			let targetwound=ww.targetwound;
			if(!!targetwound){
				double tgtwsc=1.4+targetwound.width*0.1;
				double tgtwa=0;
				if(tgtwsc>3.){
					tgtwa=3.-tgtwsc;
					tgtwsc=3.;
				}
				sb.drawimage(
					"BLUDC0",(-15,!!targetwound.width&&hpl.flip?-8:-7),
					sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_RIGHT,
					0.01+targetwound.depth*0.1+tgtwa,scale:(1,1)*tgtwsc
				);
			}
		}
	}

	override string gethelptext(){
		int usedon=weaponstatus[MEDSPRAY_USEDON];
		return
		WEPHELP_RELOAD.."  Take off armour\n"
		..WEPHELP_INJECTOR
		.."\n  ...while pressing:\n"
		.."  <\cunothing"..WEPHELP_RGCOL..">  Treat wounds\n"
		.."  "..WEPHELP_ZOOM.."  Treat burns\n"
		;
	}
	action void A_FirstAidReady(){
		A_WeaponReady(WRF_NOFIRE|WRF_ALLOWUSER1|WRF_ALLOWUSER3);
		if(!player)return;
		int bt=player.cmd.buttons;

/*
		if(
			invoker.icon==invoker.default.icon
			&&invoker.weaponstatus[MEDSPRAY_USEDON]>=0
		)invoker.icon=texman.checkfortexture("BLUDIKIT",TexMan.Type_MiscPatch);
*/

		//don't do the other stuff if holding reload
		//LET THE RELOAD STATE HANDLE EVERYTHING ELSE
		if(bt&BT_RELOAD){
			setweaponstate("reload");
			return;
		}

		//wait for the player to decide what they're doing
		if(bt&BT_ATTACK&&bt&BT_ALTATTACK)return;

		//just gotta let go
		if(!(bt&(BT_ATTACK|BT_ALTATTACK)))invoker.targetwound=null;

		//use on someone else
		if(bt&BT_ALTATTACK){

			if(
				(bt&BT_FIREMODE)
				&&!(bt&BT_ZOOM)
			)setweaponstate("nope");
			else 

			if(invoker.weaponstatus[MEDSPRAY_SECONDFLESH]<1){
				A_WeaponMessage("You are out of first aid spray.");
				setweaponstate("nope");
			}else setweaponstate("fireother");
			return;
		}

		//self
		if(bt&BT_ATTACK){
			invoker.bwimpy_weapon=false;  //uncloak

			//radsuit, etc. blocks everything
			let blockinv=HDWoundFixer.CheckCovered(self,CHECKCOV_ONLYFULL);
			if(blockinv){
				A_TakeOffFirst(blockinv.gettag());
				setweaponstate("nope");
				return;
			}
			if(pitch<min(player.maxpitch,80)){
				//move downwards
				let hdp=hdplayerpawn(self);
				if(hdp)hdp.gunbraced=false;
				A_MuzzleClimb(0,5,0,5);
			}else{
				bool scanning=bt&BT_FIREMODE;
				//armour blocks everything except scan
				let blockinv=HDWoundFixer.CheckCovered(self,CHECKCOV_CHECKBODY);
				if(
					!scanning
					&&blockinv
				){
					A_TakeOffFirst(blockinv.gettag());
					setweaponstate("nope");
					return;
				}

				//diagnose
				if(scanning){
					setweaponstate("nope");
					return;
				}

				//act upon flesh
				if(invoker.weaponstatus[MEDSPRAY_SECONDFLESH]<1){
					A_WeaponMessage("You are out of first aid spray.");
					setweaponstate("nope");
					return;
				}
				if(bt&BT_ZOOM){
					//treat burns
					let a=HDPlayerPawn(self);
					if(a){
						if(a.burncount<1){
							A_WeaponMessage("You have no burns to treat.");
							setweaponstate("nope");
						}else setweaponstate("patchburns");
						return;
					}
				}else{
					//treat wounds
					if(!hdbleedingwound.findbiggest(self,HDBW_FINDPATCHED)){
						A_WeaponMessage("You have no wounds to treat.");
						setweaponstate("nope");
					}else setweaponstate("patchup");
					return;
				}
			}
		}
		invoker.bwimpy_weapon=true;
		int mbl=invoker.weaponstatus[MEDSPRAY_BLOOD];
		if(mbl>random(5,64)){
			invoker.weaponstatus[MEDSPRAY_BLOOD]--;
			if(mbl>random(0,255))A_SpawnItemEx(bloodtype,
				frandom(0,3),frandom(-0.3,0.3)*radius,
				height*frandom(0.,0.3),
				flags:SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION
			);
		}
	}
	states{
	select:
		TNT1 A 10{
			if(!DoHelpText()) return;
			A_WeaponMessage("\cg+++ \cjFIRST AID SPRAY \cg+++\c-\n\n\nPress and hold Fire\nto treat your wounds.",175);
		}
		goto super::select;
	ready:
		TNT1 A 1 A_FirstAidReady();
		goto readyend;
	flashstaple:
		TNT1 A 1{
			A_StartSound("firstaidcan/spray",CHAN_WEAPON);
			//A_StartSound("misc/bulletflesh",CHAN_BODY,CHANF_OVERLAP);
			invoker.weaponstatus[MEDSPRAY_BLOOD]+=random(0,2);
			if(hdplayerpawn(self)){
				HDF.Give(self,"SecondFlesh",1);
			}else givebody(3);
		}goto flashend;
	flashnail:
		TNT1 A 1{
			A_StartSound("firstaidcan/spray",CHAN_WEAPON,CHANF_OVERLAP);
			//A_StartSound("misc/bulletflesh",CHAN_BODY,CHANF_OVERLAP);
			invoker.weaponstatus[MEDSPRAY_BLOOD]+=random(1,2);
		}goto flashend;
	flashend:
		TNT1 A 1{
			givebody(1);
			damagemobj(invoker,self,1,"staples");
			//A_ZoomRecoil(0.9);
			A_ChangeVelocity(frandom(-0.2,0.03),frandom(-0.2,0.2),0.4,CVF_RELATIVE);
		}
		stop;
	altfire:
	althold:
	fireother:
		//TNT1 A 0 A_JumpIf(pressingfiremode()&&!pressingzoom(),"diagnoseother");
		TNT1 A 10{
			flinetracedata mediline;
			linetrace(
				angle,radius*4,pitch,
				offsetz:height*0.8,
				data:mediline
			);
			let patient=HDPlayerPawn(mediline.hitactor);
			if(!patient){
				//resolve where the target is not an HD player
				if(
					mediline.hitactor
					&&mediline.hitactor.bsolid
					&&!mediline.hitactor.bnoblood
					&&!mediline.hitactor.bspecialfiredamage  //must see wounds to staple them
					&&(
						mediline.hitactor.bloodtype=="HDMasterBlood"
						||mediline.hitactor.bloodtype=="Blood"
					)
					&&(
						mediline.hitactor is "HDHumanoid"
					)
				){
					let mb=hdmobbase(mediline.hitactor);
					if(
						mediline.hitactor.health<mediline.hitactor.spawnhealth()
						||(
							mb
							&&mb.bodydamage>0
						)
					){
						if(invoker.weaponstatus[MEDSPRAY_SECONDFLESH]<1){
							A_WeaponMessage("You are out of first aid spray.");
							return resolvestate("nope");
						}
						invoker.target=mediline.hitactor;
						return resolvestate("patchupother");
					}else{
						A_WeaponMessage("They have no injuries to treat.");
						return resolvestate("nope");
					}
				}else{
					if(DoHelpText())A_WeaponMessage("Nothing to be done here.\n\nSpray thyself? (press fire)",150);
					return resolvestate("nope");
				}
			}
			if(
				patient.player
				&&invoker.weaponstatus[MEDSPRAY_USEDON]>=0
				&&invoker.weaponstatus[MEDSPRAY_USEDON]!=patient.playernumber()
			){
			//if(DoHelpText(patient))HDWeapon.ForceWeaponMessage(patient,string.format("Run away!\n\n%s is trying to stab you\n\nwith a used syringe!!!",player.getusername()));
			//if(DoHelpText())A_WeaponMessage("Why are you coating your teammate\n\nin second flesh!?");
			}else if(IsMoving.Count(patient)>4){
				if(DoHelpText(patient))HDWeapon.ForceWeaponMessage(patient,string.format("%s is trying to use first aid spray on you.\nStay still to let them or tell them to leave...",player.getusername()));
				if(DoHelpText())A_WeaponMessage("You'll need them to stay still...");
				return resolvestate("nope");
			}
			let blockinv=HDWoundFixer.CheckCovered(patient,CHECKCOV_CHECKBODY);
			if(
				!patient.player.bot
				&&blockinv
			){
				if(DoHelpText())A_WeaponMessage("Get them to take off their "..blockinv.gettag().." first!\n\n(\cdhd_strip\c- in the console)",100);
				return resolvestate("nope");
			}
			if(
				!(getplayerinput(MODINPUT_BUTTONS)&BT_ZOOM)
				&&!hdbleedingwound.findbiggest(patient,HDBW_FINDPATCHED)
			){
				A_WeaponMessage("They have no wounds to treat.");
				return resolvestate("nope");
			}
			if(
				getplayerinput(MODINPUT_BUTTONS)&BT_ZOOM
				&&patient.burncount<1
			){
				A_WeaponMessage("They have no burns to treat.");
				return resolvestate("nope");
			}
			if(invoker.weaponstatus[MEDSPRAY_SECONDFLESH]<1){
				A_WeaponMessage("You are out of first aid spray.");
				return resolvestate("nope");
			}
			invoker.target=patient;
			return resolvestate("patchupother");
		}goto nope;
	patchupother:
		TNT1 A 0{
			if(
				invoker.target
				&&invoker.target.player
			)invoker.weaponstatus[MEDSPRAY_USEDON]=invoker.target.playernumber();
			else invoker.weaponstatus[MEDSPRAY_USEDON]=FIRSTAID_NOTAPLAYER;
			invoker.patientname=invoker.target.gettag();
		}
		TNT1 A 0 A_JumpIf(pressingzoom(),"patchburnsother");
		TNT1 A 10{
			invoker.weaponstatus[MEDSPRAY_SECONDFLESH]--;
			if(invoker.target){
				invoker.target.A_StartSound("firstaidcan/spray",CHAN_WEAPON,CHANF_OVERLAP);
				//invoker.target.A_StartSound("misc/bulletflesh",CHAN_BODY,CHANF_OVERLAP);
			}
		}
		TNT1 AAAAA 3{
			let itg=invoker.target;
			
			if(
				!itg
				||absangle(angle,angleto(itg))>60
				||distance3dsquared(itg)>(radius*radius*16)
			){
				invoker.target=null;
				A_WeaponMessage("Target disconnected!",15);
				setweaponstate("nope");
				return;
			}
			A_StartSound("firstaidcan/spray",CHAN_WEAPON);
			invoker.weaponstatus[MEDSPRAY_BLOOD]+=random(0,1);

			itg.A_StartSound("misc/smallslop",CHAN_BODY,CHANF_OVERLAP);
			if(!random(0,3))invoker.setstatelabel("patchupend");
			itg.givebody(1);
			itg.damagemobj(invoker,null,1,"staples",DMG_FORCED);

			if(hdplayerpawn(itg)){
				HDF.Give(itg,"SecondFlesh",1);
			}else{
				if(hdmobbase(itg))hdmobbase(itg).bodydamage-=3;
				itg.givebody(3);
				hdmobbase.forcepain(itg);
			}
		}goto patchupend;
	patchup:
		TNT1 A 10;
		TNT1 A 0{
			if(invoker.weaponstatus[MEDSPRAY_SECONDFLESH]<1){
				A_WeaponMessage("You are out of first aid spray.");
				setweaponstate("nope");
				return;
			}
			invoker.weaponstatus[MEDSPRAY_USEDON]=playernumber();
			invoker.weaponstatus[MEDSPRAY_SECONDFLESH]--;
		}
		TNT1 A 10 A_Overlay(3,"flashnail");
		TNT1 AAAAA random(4,5){
			invoker.target=self;
			A_Overlay(3,"flashstaple");
			if(!random(0,3))invoker.setstatelabel("patchupend");
		}goto patchupend;
	patchupend:
		TNT1 A 10{
			let itg=invoker.target;
			if(itg){
				let tgw=invoker.targetwound;
				if(
					!tgw
					||tgw.bleeder!=itg
				){
					tgw=hdbleedingwound.findbiggest(itg,HDBW_FINDPATCHED);
					invoker.targetwound=tgw;
				}
				if(
					tgw
					&&!tgw.depth
					&&!tgw.patched
				){
					invoker.targetwound=null;
					A_WeaponMessage("Wound successfully sealed.",70);
					setweaponstate("patchdone");
					return;
				}
				if(
					tgw
					&&tgw.patch(frandom(0.8,1.2),true)
				){
					tgw.depth+=tgw.patched;
					tgw.patched=0;
				}
			}
		}
		TNT1 A 0 A_ClearRefire();
		goto ready;
	patchdone:
		TNT1 A 4;
		TNT1 A 4 A_StartSound("firstaidcan/spray",CHAN_WEAPON,CHANF_OVERLAP);
		TNT1 A 3 A_SpawnItemEx(bloodtype,
			frandom(0,3),frandom(-0.3,0.3)*radius,
			height*frandom(0.,0.3),
			flags:SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION
		);
		TNT1 A 2;
		goto nope;
	patchburns:
		TNT1 A 6;
		TNT1 A 8{
			if(!HDPlayerPawn(self))return;
			invoker.weaponstatus[MEDSPRAY_BLOOD]+=random(1,2);
			invoker.weaponstatus[MEDSPRAY_USEDON]=playernumber();
			int fleshgive=min(FIRSTAID_FLESHGIVE,invoker.weaponstatus[MEDSPRAY_SECONDFLESH]);
			invoker.weaponstatus[MEDSPRAY_SECONDFLESH]-=fleshgive;
			A_StartSound("firstaidcan/spray",CHAN_WEAPON);
			//A_StartSound("misc/bulletflesh",CHAN_BODY,CHANF_OVERLAP);
			//A_StartSound("misc/smallslop",CHAN_BODY,CHANF_OVERLAP);
			actor a=spawn("SecondFleshBeast",pos,ALLOW_REPLACE);
			a.target=self;
			a.stamina=fleshgive;
		}
		goto ready;
	patchburnsother:
		TNT1 A 10{
			if(invoker.target){
				invoker.weaponstatus[MEDSPRAY_BLOOD]+=random(1,2);
				int fleshgive=min(FIRSTAID_FLESHGIVE,invoker.weaponstatus[MEDSPRAY_SECONDFLESH]);
				invoker.weaponstatus[MEDSPRAY_SECONDFLESH]-=fleshgive;
				invoker.target.A_StartSound("firstaidcan/spray",CHAN_WEAPON);
				//invoker.target.A_StartSound("misc/bulletflesh",CHAN_BODY,CHANF_OVERLAP);
				//invoker.target.A_StartSound("misc/smallslop",CHAN_BODY,CHANF_OVERLAP);
				actor a=spawn("SecondFleshBeast",invoker.target.pos,ALLOW_REPLACE);
				a.target=invoker.target;
				a.stamina=fleshgive;
			}
		}
		goto nope;

	spawn:
		FAID B -1 A_JumpIf(!invoker.weaponstatus[MEDSPRAY_SECONDFLESH]>0,1);
		FAID C -1;
		wait;
	}

	override string pickupmessage(){
		if(weaponstatus[MEDSPRAY_SECONDFLESH]<FIRSTAID_MAXFLESH)return "Picked up a used can of first aid spray.";
		if(weaponstatus[MEDSPRAY_SECONDFLESH]<=0)return "Picked up an empty can of first aid spray.";

		return "Picked up a can of first aid spray.";
	}
}