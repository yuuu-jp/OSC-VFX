using UnityEngine;

public class GrowthSimulation : MonoBehaviour
{
    [SerializeField] private Material _material;
    [SerializeField] private float _lerpDuration = 3.0f;
    [SerializeField] private float _waitSeconds = 3.0f;

    private float _time;
    private float _currentValue;
    private bool _isIncreasing = true;
    private static readonly int Size = Shader.PropertyToID("_Size");
    private static readonly int Alpha = Shader.PropertyToID("_Alpha");

    void Update()
    {
        // increasingがtrueの場合、0から1に向けて線形補間
        if (_isIncreasing)
        {
            _time += Time.deltaTime / _lerpDuration;
            _currentValue = Mathf.Lerp(0.0f, 1.0f, _time);

            if (_time >= 1.0f)
            {
                _time = 0.0f;
                _isIncreasing = false;
            }
        }
        else
        {
            _time += Time.deltaTime / _waitSeconds;

            if (_time >= 1.0f)
            {
                _time = 0.0f;
                _isIncreasing = true;
                _currentValue = 0.0f;
            }
        }

        _material.SetFloat(Size, _currentValue);
        _material.SetFloat(Alpha, _currentValue);
    }
}