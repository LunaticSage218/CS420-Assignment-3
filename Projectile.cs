using Godot;
using System;

public partial class Projectile : Area2D
{
	[Export] public float Speed = 300.0f;
	[Export] public float HomingStrength = 5.0f;
	[Export] public float MaxTurnRate = 3.0f;
	[Export] public float GroundY = 580.0f; // Maximum Y position (ground level)
	private Vector2 _direction = Vector2.Right;

	[Export] 
	public Vector2 Direction {
		get => _direction;
		set {
			_direction = value.Normalized();
			Rotation = _direction.Angle();
		}
	}

	private Node2D _targetEnemy = null;
	private bool _hasTarget = false;

	public override void _Ready()
	{
		AddToGroup("projectiles");

		// Connect both BodyEntered and AreaEntered for maximum compatibility
		BodyEntered += OnBodyEntered;
		AreaEntered += OnAreaEntered;

		// Set up collision detection to detect both bodies and areas
		// Layer 1 = player/projectiles, Layer 2 = enemies
		CollisionMask = 6; // Detect both layer 2 (enemies) and layer 3 (enemy hitboxes) - binary 110 = 6
		CollisionLayer = 4; // Projectile is on layer 3 - binary 100 = 4

		// Delay enemy search to ensure enemies are in the scene
		CallDeferred(nameof(FindNearestEnemy));

		// Auto-destroy after 5 seconds
		GetTree().CreateTimer(5.0).Timeout += QueueFree;
	}

	public override void _PhysicsProcess(double delta)
	{
		float dt = (float)delta;

		// Acquire target if we don't have one yet
		if (!_hasTarget)
		{
			FindNearestEnemy();
		}

		if (_hasTarget && IsInstanceValid(_targetEnemy))
		{
			Vector2 toTarget = (_targetEnemy.GlobalPosition - GlobalPosition).Normalized();

			// Calculate shortest angle difference manually
			float currentAngle = _direction.Angle();
			float targetAngle = toTarget.Angle();
			float angleDiff = targetAngle - currentAngle;
			while (angleDiff > Mathf.Pi) angleDiff -= 2 * Mathf.Pi;
			while (angleDiff < -Mathf.Pi) angleDiff += 2 * Mathf.Pi;

			// Clamp turn rate
			float turn = Mathf.Clamp(angleDiff, -MaxTurnRate * (float)delta, MaxTurnRate * (float)delta);

			// Apply rotation
			_direction = _direction.Rotated(turn).Normalized();
		}

		// Move projectile
		GlobalPosition += _direction * Speed * dt;

		// Keep projectile above ground
		if (GlobalPosition.Y > GroundY)
		{
			GlobalPosition = new Vector2(GlobalPosition.X, GroundY);
			// Optionally destroy the projectile when it hits the ground
			QueueFree();
		}

		// Rotate sprite to face direction
		Rotation = _direction.Angle();

		// Check for overlapping areas/bodies each frame
		CheckOverlappingCollisions();
	}

	private void CheckOverlappingCollisions()
	{
		// Check overlapping bodies (CharacterBody2D enemies)
		var overlapping_bodies = GetOverlappingBodies();
		foreach (var body in overlapping_bodies)
		{
			if (body.IsInGroup("enemies"))
			{
				HitEnemy(body as Node2D);
				return;
			}
		}

		// Check overlapping areas (AttackBox/HitBox areas)
		var overlapping_areas = GetOverlappingAreas();
		foreach (var area in overlapping_areas)
		{
			// Check if this area belongs to an enemy
			var parent = area.GetParent();
			if (parent != null && parent.IsInGroup("enemies"))
			{
				HitEnemy(parent as Node2D);
				return;
			}
			
			// Also check if the area itself is tagged as enemy
			if (area.IsInGroup("enemies"))
			{
				HitEnemy(area as Node2D);
				return;
			}
		}
	}

	public void SetDirection(Vector2 dir)
	{
		_direction = dir.Normalized();
		Rotation = _direction.Angle();
	}

	private void FindNearestEnemy()
	{
		var enemies = GetTree().GetNodesInGroup("enemies");
		float closestDistance = float.MaxValue;
		_targetEnemy = null;

		foreach (Node node in enemies)
		{
			if (node is Node2D enemy && IsInstanceValid(enemy))
			{
				float distance = GlobalPosition.DistanceTo(enemy.GlobalPosition);
				if (distance < closestDistance)
				{
					closestDistance = distance;
					_targetEnemy = enemy;
					_hasTarget = true;
				}
			}
		}
	}

	private void OnBodyEntered(Node2D body)
	{
		if (body.IsInGroup("enemies"))
		{
			HitEnemy(body);
		}
	}

	private void OnAreaEntered(Area2D area)
	{
		// Check if the area's parent is an enemy
		var parent = area.GetParent();
		if (parent != null && parent.IsInGroup("enemies"))
		{
			HitEnemy(parent as Node2D);
			return;
		}
		
		// Check if area itself is an enemy
		if (area.IsInGroup("enemies"))
		{
			HitEnemy(area as Node2D);
		}
	}

	private void HitEnemy(Node2D enemy)
	{
		if (enemy == null || !IsInstanceValid(enemy))
			return;
		
		if (enemy.HasMethod("defeat"))
		{
			enemy.Call("defeat");
			GD.Print("Called defeat() on enemy");
		}
		else
		{
			GD.Print("WARNING: Enemy does not have defeat() method!");
		}
		
		QueueFree();
	}
}
