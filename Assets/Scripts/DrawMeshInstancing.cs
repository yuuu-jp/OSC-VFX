using System.Collections.Generic;
using UnityEngine;

namespace TestGPUInstancing
{
    public class DrawMeshInstancing : MonoBehaviour
    {
        [SerializeField] private Mesh _mesh;
        [SerializeField] private Material _material;
        [SerializeField] private float _areaWidth = 5.0f;
        [SerializeField] private float _areaHeight = 15.0f;
        [SerializeField] private float _objectHeight = 1.0f;

        private readonly int _meshCount = 1023;
        private Matrix4x4[] _matrices;
        private List<Vector3> _positions;

        private void Start()
        {
            _positions = GenerateCoordinates(_areaWidth, _areaHeight, _meshCount, transform.position);
            _matrices = new Matrix4x4[_positions.Count];

            for (var i = 0; i < _positions.Count; i++)
            {
                var pos = _positions[i] * Random.Range(0.99f, 1.01f);
                var meshPosition = new Vector3(pos.x + 2.5f, _positions[i].y, pos.z + 0.5f); // Meshによって微妙に原点がずれるので調整。
                _matrices[i % _meshCount] =
                    Matrix4x4.TRS(meshPosition, Quaternion.identity, new Vector3(1, _objectHeight, 1));
            }
        }

        List<Vector3> GenerateCoordinates(float width, float height, int totalCoordinates, Vector3 center)
        {
            var coordinateList = new List<Vector3>();
            var rowCount = Mathf.FloorToInt(Mathf.Sqrt(totalCoordinates * (width / height)));
            var columnCount = totalCoordinates / rowCount;

            var spacingX = width / rowCount;
            var spacingZ = height / columnCount;

            for (var col = 0; col < columnCount; col++)
            {
                for (var row = 0; row < rowCount; row++)
                {
                    var x = row * spacingX - width / 2 + center.x;
                    var z = col * spacingZ - height / 2 + center.z;
                    var pos = new Vector3(x, center.y + _mesh.bounds.size.y * 0.25f * _objectHeight, z);
                    coordinateList.Add(pos);

                    if (coordinateList.Count >= totalCoordinates)
                        return coordinateList;
                }
            }

            return coordinateList;
        }

        private void Update()
        {
            Graphics.DrawMeshInstanced(_mesh, 0, _material, _matrices, _positions.Count);
        }
    }
}