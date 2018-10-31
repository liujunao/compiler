/*
* 注释
* 
*/
int a, b, c;
// int main(){
//     a++;
//     b--;
// }
float m, n;
char xx;
int d, arr[3];
int fibo(int a)
{
    m = xx;
    5 = m;
    b = m / xx;
    b++;
    c--;
    b += a + 1;
    c -= 1;
    if (a == 1 || a == 2)
        return 1;
    return fibo(a - 1) + fibo(a - 2);
}
int main()
{
    int m, n, i;
    m = read();
    i = 1;
    fibo(1.0);
    while (i <= m)
    {
        n = fibo(i);
        write(n);
        i = i + 1;
    }
    return 1;
}
