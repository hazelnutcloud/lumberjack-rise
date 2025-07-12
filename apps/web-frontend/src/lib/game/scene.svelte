<script lang="ts">
	import { T } from '@threlte/core';
	import { Gizmo, OrbitControls } from '@threlte/extras';
</script>

<T.PerspectiveCamera position={[10, 15, 10]} makeDefault lookAt.y={0}>
	<OrbitControls />
	<Gizmo></Gizmo>
</T.PerspectiveCamera>

<T.Mesh>
	<T.BoxGeometry></T.BoxGeometry>
	<T.MeshBasicMaterial></T.MeshBasicMaterial>
</T.Mesh>
