[![Build Status](https://travis-ci.org/opussf/TabardTell.svg?branch=master)](https://travis-ci.org/opussf/TabardTell)
=====

Tabard Tell
=====

This addon shows the faction's reputation in the tooltip for the respective tabard.

As of v0.8, it will also find and equip a tabard in your inventory with the lowest reputation.
This is optional, and can be turned off.

## Idea:
I got tired of looking in the reputation frame to figure out which tabard I wanted to wear.
And it just sort of made sense.

## Goals:
* Simple to use addon
* Little to No configuration

## How to use:
Install the addon, mouse over a tabard in your inventory.

Enable swapping and carry your tabards with you.

## Known bugs:
The equip does not work if you zone into a dungeon, and the dungeon group is in combat.
A fix for this would be to check the equipped tabard and try again in a few seconds.
Or to check for reasons why it cannot be equipped and equip it after those reasons are gone.

## Versions
```
0.11.1 Fixed a bug where corpse running would capture the tabard to wear outside an instance.
0.11   Fix a bug where the tabard equipped outside the dungeon is not replaced
       Cleaned up the Tabard switching messages.
0.10.1 Fix a bug for casting, not just channeling spells.
0.10   Fix a bug for exchanging Exalted tabards if you are still casting after combat (healer).
0.9    Once reaching Exalted with a faction, a tabard will be replaced after combat.
0.8.4  Removing Debug print statements showing tabards in inventory
0.8.3  Fixed bug with parsing Tabard name
0.8.2  Fixed bug with keeping Tabard to equip coming out of dungeon
0.8.1  Fixed bug with Darkspear Tabard (Darkspear Trolls rep) not equiping
0.8    Wrapping in an Instance Auto Equip
       Super Simple configuration system to turn it on or off.
0.7.1  WoD update
0.7    Last version before WoD
0.4    Fixed a bug with faction headers being folded, therefore being 'hidden'
0.3b   Fix a bug if the tooltip for not for an item.
0.2b   Found and fixed a bug with which line the "Equip:" text is in.
0.1b   Initial version
       Standing # / # (%)  into the tooltip for a faction tabard.
```