package apps.todoappgcp.repository;

import apps.todoappgcp.model.Todo;
import org.springframework.data.repository.CrudRepository;

public interface TodoRepository extends CrudRepository<Todo, Long> {}
