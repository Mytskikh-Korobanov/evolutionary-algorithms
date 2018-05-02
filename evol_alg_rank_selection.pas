program evol_alg_rank_selection;
// Дарвиновский эволюционный алгоритм (генетический алгоритм)
// Максимизация площади прямоугольника с заданным периметром

const
  M = 2;

type
  chromos = record
    genes: array [1..M] of real;
  end;

var
  start: longint; // число особей в популяции (в первом поколении)
  n: longint; // число особей в популяции (в данном поколении)
  populat: array of chromos; // особи
  confines: array [1..2, 1..M] of real; // ограничения на значения генов
  // confines[1,x] ограничивает значение гена x снизу;
  // confines[2,x] ограничивает значение гена x сверху
  marks: array of real; // результаты оценки особей
  winners: array of longint; // особи, оставляющие потомство
  w: longint; // количество особей, оставляющих потомство
  protocol: text; // протокол вычислений
  name: string; // имя файла протокола вычислений
  count: longint; // счётчик поколений
  // параметры задачи
  p: real; // периметр

// линейная сортировка по неубыванию
// n - число элементов в массиве a
// keys - массив из номеровов элементов массива (ключей) после сортировки
procedure lin_sort(n: longint; a: array of real; var keys: array of longint);
var
  a1: array of real;
  i, j: longint;
  min: longint;
  t: real;
  k: longint;
begin
  setlength(a, n);
  setlength(keys, n);
  setlength(a1, n);
  for i := 0 to n-1 do
    a1[i] := a[i];
  for i := 0 to n-1 do
    keys[i] := i;
  for i := 0 to n-1 do
  begin
    min := i;
    for j := i+1 to n-1 do
      if a1[j] < a1[min] then min := j;
    t := a1[i];
    a1[i] := a1[min];
    a1[min] := t;
    k := keys[i];
    keys[i] := keys[min];
    keys[min] := k;
  end;
end;

// формирование набора из n различных случайных чисел от 0 до n-1
procedure rand_set(n: longint; var res: array of longint);
var
  a: array of longint;
  i: longint;
  m: longint;
  procedure del(m: longint);
  var
    i: longint;
  begin
    for i := m to n-2 do
      a[i] := a[i+1];
    setlength(a, n-1);
    n := n - 1;
  end;
begin
  setlength(a, n);
  setlength(res, n);
  for i := 0 to n-1 do
    a[i] := i;
  for i := 0 to n-1 do
  begin
    m := random(n);
    res[i] := a[m];
    del(m);
  end;
end;
  
// определяет оптимизируемую характеристику особи (варианта решения);
// моделирование приспособленности фенотипа
function solver(a: chromos): real;
begin
  with a do
  begin
    if genes[1] + genes[2] <> p/2
      then solver := 0
      else solver := genes[1]*genes[2];
  end;
end;

// удаление особи
procedure del_chr(a: longint);
var
  i: longint;
begin
  for i := a to n-2 do
  begin
    marks[i] := marks[i+1];
    populat[i] := populat[i+1];
  end;
  setlength(marks, n-1);
  setlength(populat, n-1);
  n := n - 1;
end;

// добавление особи
procedure add_chr(a: chromos);
begin
  setlength(marks, n+1);
  setlength(populat, n+1);
  populat[n] := a;
  n := n+1;
end;

// инициализация
procedure init;
var
  i: longint;
  a: chromos;
begin
  n := 0;
  p := 56;
  confines[1, 1] := 0;
  confines[2, 1] := p/2;
  confines[1, 2] := 0;
  confines[2, 2] := p/2;
  for i := 1 to start do
  begin
    with a do
    begin
      genes[1] := random*(confines[2,1] - confines[1,1]);
      genes[2] := p/2 - genes[1];
    end;
    add_chr(a);
  end;
end;

// сравнение (оценка)
procedure compare;
var
  i: longint;
begin
  for i := 0 to n-1 do
    marks[i] := solver(populat[i]);
end;

// метод отбора рулеткой
procedure roulette(winners: longint; var a: array of longint);
var
  r: array of real;
  i, j: longint;
  sum: real;
  m: real;
begin
  setlength(a, winners);
  setlength(r, n);
  sum := 0;
  for i := 0 to n-1 do
    sum := sum + marks[i];
  r[0] := marks[0] / sum;
  for i := 1 to n-1 do
  begin
    r[i] := marks[i] / sum + r[i-1];
  end;
  for i := 0 to winners-1 do
  begin
    m := random;
    j := 1;
    while (r[j] < m) and (j <> n-1) do // можно для ускорения применить бинарный поиск
      j := j +1;
    j := j - 1;
    a[i] := j;
  end;
end;

// ранговая селекция
procedure rank_selection(winners: longint; var a: array of longint);
var
  r, keys: array of longint;
  i, j: longint;
  m: longint;
begin
  setlength(a, winners);
  setlength(keys, n);
  lin_sort(n, marks, keys); // для ускорения работы можно применить быструю сортировку
  m := 1;
  setlength(r, 1);
  r[0] := keys[0];
  for i := 1 to n-1 do
  begin
    if marks[keys[i]] <> marks[keys[i-1]] then m := m + 1;
    setlength(r, length(r) + m);
    for j := 0 to m-1 do
      r[i+j] := keys[i];
  end;
  for i := 0 to winners-1 do
    a[i] := r[random(length(r))];
end;

// турнирная селекция
procedure tournament_selection(var winners: longint; var a: array of longint);
var
  i, j: longint;
  k: longint; // количество особебей в группе
  m: longint; // количество победителей
  list: array of longint; // участники турнира (распределённые по группам)
  tournament: array of real; // группа (характеристики)
  t_keys: array of longint; // группа (указатели)
begin
  k := 3; // параметр турнирной селекции
  m := 2; // параметр турнирной селекции
  winners := m*(n div k);
  if n mod k <> 0 then winners := winners + m;
  setlength(a, winners);
  setlength(list, n);
  rand_set(n, list);
  setlength(tournament, k);
  setlength(t_keys, k);
  for i := 1 to n div k do
  begin
    for j := 0 to k-1 do
      tournament[j] := marks[list[(i-1)*k + j]];
    lin_sort(k, tournament, t_keys);
    for j := 0 to m-1 do
      a[(i-1)*k + j] := (i-1)*k + t_keys[k-1-j];
  end;
  if n mod k <> 0
    then
    begin
      setlength(tournament, n mod k);
      setlength(t_keys, n mod k);
      for j := 0 to n mod k - 1 do
        tournament[j] := marks[list[(i-1)*k + j]];
      lin_sort(n mod k, tournament, t_keys);
      for j := 0 to n mod k - 1 do
        a[(i-1)*k + j] := (i-1)*k + t_keys[n mod k - 1 - j];
    end;
end;

// отбор
procedure select(var winners: longint; var a: array of longint);
begin
  rank_selection(winners, a);
  // количество особей, оставляющих потомство, должно быть чётным
end;

// размножение (реализация соответствует генетическому алгоритму)
procedure duplicat;
var
  p: longint; // конечный индекс первой хромосомы при делении
  i, j: longint;
  q: array of longint; // случайная очередь
  a: chromos;
  r: real; // случайная величина
  t: longint; // случайная величина
  y: real; // вероятность мутаций
begin
  setlength(q, w);
  rand_set(w, q);
  // вывод данных в протокол вычислений о скрещивающихся решениях
  writeln(protocol, 'Пары скрещивающихся значений:');
  for i := 0 to (w div 2) - 1 do
    write(protocol, '(', winners[q[i]], ', ', winners[q[i + (w div 2)]], '); ');
  writeln(protocol);
  writeln(protocol, 'Конечный индекс первой хромосомы при делении в данных парах:');
  y := 0.1;
  for i := 0 to (w div 2) - 1 do
  begin
    p := random(M-1)+1;
    write(protocol, p, ' ');
    with a do
    begin
      // формирование первой особи
      for j := 1 to p do
        genes[j] := populat[winners[q[i]]].genes[j];
      for j := p to M do
        genes[j] := populat[winners[q[i + (w div 2)]]].genes[j];
      r := random;
      if r <= y
        then
        begin
          t := 1+random(M);
          genes[t] := random*(confines[2,t] - confines[1,t]);
        end;
    end;
    add_chr(a);
    with a do
    begin
      // формирование второй особи
      for j := 1 to p do
        genes[j] := populat[winners[q[i + (w div 2)]]].genes[j];
      for j := p to M do
        genes[j] := populat[winners[q[i]]].genes[j];
      r := random;
      if r <= y
        then
        begin
          t := 1+random(M);
          genes[t] := random*(confines[2,t] - confines[1,t]);
        end;
    end;
    add_chr(a);
  end;
  writeln(protocol);
end;

// замещение
procedure substit;
var
  a: array of real;
  k: array of longint;
  i: longint;
  m: longint; // число лучших решений переходящих в следущее поколение
begin
  setlength(a, n - w);
  for i := 0 to n - w - 1 do
    a[i] := marks[i];
  setlength(k, n - w);
  lin_sort(n-w, a, k);
  m := 2;
  for i := n - w - m - 1 downto 0 do
    del_chr(k[i]);
end;

// критерий остановки оптимизации
function stop: boolean;
var
  a: array of longint;
  b: array of boolean;
  i, j, k: longint;
  p: real; // доля одинаковых решений достаточная для остановки
  res: boolean;
begin
  p := 0.86; // параметр остановки
  setlength(a, n);
  setlength(b, n);
  for i := 0 to n-1 do
  begin
    a[i] := 0;
    for j := 0 to n-1 do
      if i<>j 
        then
        begin
          b[j] := true;
          for k := 1 to M do
            if populat[i].genes[k] <> populat[j].genes[k]
              then b[j] := false;
          if b[j] then a[i] := a[i] + 1;
        end;
  end;
  res := false;
  for i := 0 to n-1 do
    if a[i]/n >= p then res := true;
  stop := res;
end;

// вывод в протокол вычислений текущего поколения
procedure write_gen;
var
  i, j, k: longint;
begin
  writeln(protocol, 'Поколение №', count);
  write(protocol, '  Вариант ');
  for i := 1 to M do
    write(protocol, '| Поле ', i, ' ');
  writeln(protocol, '| Оценка');
  for i := 0 to n-1 do
  begin
    write(protocol, i: 6, '    ');
    for j := 1 to M do
    begin
      write(protocol, '|', populat[i].genes[j]:8:2);
      k := j;
      while k div 10 <> 0 do
      begin
        write(protocol, ' ');
        k := k div 10;
      end;
    end;
    writeln(protocol, '|', marks[i]:8:2);
  end;
end;

// вывод в протокол вычислений вариантов победителей отбора
procedure write_winners;
var
  i: longint;
begin
  writeln(protocol, 'Варианты победители:');
  for i := 0 to w-1 do
    write(protocol, winners[i], ' ');
  writeln(protocol);
end;

begin
  start := 10;
  writeln('Эволюционный алгоритм');
  writeln('Введите имя файла протокола вычислений:');
  readln(name);
  assign(protocol, name);
  rewrite(protocol);
  count := 0;
  w := 8;
  init;
  repeat
    count := count + 1;
    compare;
    write_gen;
    select(w, winners);
    write_winners;
    duplicat;
    substit;
    writeln(protocol);
    writeln('Вычислено поколение №', count);
  until stop;
  close(protocol);
end.