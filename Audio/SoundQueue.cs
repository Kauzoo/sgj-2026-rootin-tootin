using Godot;
using System;
using System.Collections.Generic;

[Tool]
public partial class SoundQueue : Node2D
{
	[Export]
	public int Count {get; set;} = 1;
	
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		if(GetChildCount == 0)
		{
			GD.Print("No ASP child found.");
			return;
		}
		
		var child  = GetChild(0);
		if (child is AudioStreamPlayer2D audioStreamPlayer){
			_audioStreamPlayers.Add(audioStreamPlayer)
			
			for (int i = 0; i < Count; i++)
			{
				AudioStreamPlayer2D duplicate = audioStreamPlayer.Duplicate() as AudioStreamPlayer2D; 
				AddChild(duplicate);
				_audioStreamPlayers.Add(duplicate);
			}
		}
	}
	
	
	public override string[] _GetConfigurationWarning()
	{
		if (GetChildCount() == 0)
		{
			return new string[] {"No children found. Expected ASP child"};	
		}	
		
		if (GetChildCount() is not AudioStreamPlayer2D)
		{
			return new string[] {"Expected child to be an ASP"}	
		}
		
		return base._GetConfigurationWarnings()
	}	
	
	public void PlaySound()
	{
			if(!_audioStreamPlayers[_next].Playing;
			{
				_audioStreamPlayers[_next++].Play();
				_next %= _audioStreamPlayers.Count;
			}
	}
}
